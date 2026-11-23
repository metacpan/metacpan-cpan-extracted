/*FASTA reading and writing for Cn::Bioinf, (since 2026-11-18) the scan behind
fasta_index and fasta_region, the genotype counts behind its
sex_check, parent, relatedness, concordance, hirisplex_genotypes and
blood_type, (since 2026-11-11) the codon and k-mer loops behind translate,
translate_six_frames, find_orfs and kmer_count, and (since 2026-11-17) the
genotypes and the fit behind admixture.

fasta2hash() and hash2fasta_file() used to be pure perl in ~/Scripts/bioinf.pm:
one readline, chomp and string append per line in, and one substr-sized SV per
80-column line out. Here a file is read in large blocks and every line of a
record is appended straight onto that record's SV, so no per-line SV is ever
made, and each finished sequence is shrunk to its length, which is the RAM a
proteome or genome actually needs rather than whatever the last buffer growth
left. On the file described at FASTA_BLOCK below, bioinf.pm read it in 3.83 s
with a peak RSS of 1,098 MB, and this in 0.80 s and 967 MB, 900 MB of which is
the sequences themselves; writing it back took 44.44 s and takes 0.97 s, and
the two files are byte-identical. Dropping the whitespace in sequences, which
began on 2026-10-17, costs about 15%: a made-up file of the same shape (938 MB,
400,000 records of 2,280 residues in 60-column lines, in the page cache) took
0.85 s to read before and 0.98 s after, best of five timed inside perl. The
perl side (lib/Cn/Bioinf.pm) opens and closes the files.

Every croak() and warn() here starts with C99's __func__, so a message names
the C function that raised it (read_fasta, write_fasta, translate_codons,
kmer_tally, or one of the vcf_, sex_, parent_, rel_, conc_, hps_, bt_ and admix_ ones)
and stays right if one is renamed.*/
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <stdint.h>
/*`restrict` is spelled bare, which is C99 syntax.

It is carried only by read_fasta()'s block buffer, which this file allocates
itself and reaches through nothing but that pointer and the ones derived from
it. Every other pointer here is perl's: an SV, AV or HV, or the PV inside one,
which the perl API may alias behind the code's back -- in write_fasta() a
defline and its sequence can be COW copies of the one buffer -- so the
qualifier would be a false promise. perl is built with -fno-strict-aliasing,
where `restrict` is the only disambiguation there is, but it earns nothing even
on the buffer: the loop over it stores only through memchr() and sv_catpvn(),
which are opaque calls the compiler must assume write anywhere. The generated
code for this file was byte-identical with and without it (gcc -O2 -std=gnu99,
2026-09-30), so the one annotation records the contract rather than buying
speed.

Makefile.PL probes for a C99 flag but cannot always find one. MSVC accepts the
keyword only under /std:c11 or later and otherwise spells it __restrict, older
gcc spells it __restrict__, and a strict C89 compiler has no equivalent. Map it
where a spelling exists and define it away where none does -- the same block as
~/Scripts/stats/LikeR.xs. It sits below every #include so that it cannot
rewrite a parameter named `restrict` inside a system header.*/
#if !defined(__cplusplus) && !defined(restrict)
#  if defined(_MSC_VER)
#    define restrict __restrict
#  elif !defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L
#    if defined(__GNUC__)
#      define restrict __restrict__
#    else
#      define restrict /*no spelling available; annotation only*/
#    endif
#  endif
#endif
/*PerlIO_read() request size. Reading a 928 MB FASTA of 400,000 records in
60-column lines, on this machine on 2026-09-29, took 0.84 s with 16 KiB blocks,
0.80 s with 64 KiB, 0.81 s with 256 KiB and 0.82 s with 1 MiB (best of three
each, file in the page cache), so nothing is gained past 64 KiB. Build with
DEFINE=-DFASTA_BLOCK=<bytes> to try another.*/
#ifndef FASTA_BLOCK
#define FASTA_BLOCK 65536
#endif

/*Whether c is whitespace as Python has it, which is what Biopython strips: ' '
or one of '\t' (9), '\v' (11), '\f' (12) and '\r' (13), which is the range
9..13 less the '\n' (10) that ends every line, and so is never tested. perl's
isSPACE() is not used, since that took in '\v' only from 5.18.*/
#define FASTA_SPACE(c) ((c) == ' ' || (unsigned char)((c) - '\t') < 5)

/*Whether p..e holds any FASTA_SPACE() byte, 8 bytes at a time.

With a byte-at-a-time loop, the 938 MB file described at the top of this file
took 1.46 s to read rather than 0.85 s (best of five each, 2026-10-17): gcc
-O2 does not vectorise a loop of unknown length. This takes 8 bytes at once: a space is
a zero byte of w ^ 0x2020...20, found by Alan Mycroft's haszero(), and a byte
in 9..13 is found by hasbetween(w, 8, 14), both from Sean Eron Anderson's "Bit
Twiddling Hacks" (graphics.stanford.edu/~seander/bithacks.html, sections
ZeroInWord and HasBetweenInWord). Both are exact, and work byte by byte with no
carry between bytes, so the byte order does not matter.*/
static bool any_space(const char *p, const char *e) {
	const uint64_t ones = UINT64_C(0x0101010101010101), low7 = ones * 0x7f, high = ones * 0x80;
	for (; e - p >= 8; p += 8) {
		uint64_t w;
		memcpy(&w, p, 8);// not a cast to uint64_t *, since SPARC and some ARM fault on an unaligned load
		const uint64_t sp = w ^ (ones * ' ');
		if ((sp - ones) & ~sp & high) return 1;
		if ((ones * (127 + 14) - (w & low7)) & ~w & ((w & low7) + ones * (127 - 8)) & high) return TRUE;
	}
	for (; p < e; p++) {
		if (FASTA_SPACE(*p)) return 1;
	}
	return 0;
}

/*Drop the whitespace at the end of a defline, the '\r' of a CRLF file
included, as Biopython does. It is chopped when the line ends rather than as it
is read, because a block can end inside it. Only SvCUR moves: the bytes
dropped stay in the buffer with no NUL after SvCUR, so the SV is read by its
length (sv_eq, hv_*_ent, SVf) and never as a C string, as a warning in
read_fasta() once read it and printed them.*/
static void chop_space(SV *sv) {
	STRLEN n = SvCUR(sv);
	while (n && FASTA_SPACE(SvPVX(sv)[n - 1])) n--;
	SvCUR_set(sv, n);
}

/*Append the residues in p..e to seq, leaving out the whitespace. Biopython
drops the spaces in a sequence line and the whitespace at its end; a tab inside
a line is dropped here too. A line with none, which is nearly every line, is
appended whole; otherwise each run between whitespace is one sv_catpvn().*/
static void cat_residues(pTHX_ SV *seq, const char *p, const char *e) {
	if (!any_space(p, e)) {
		sv_catpvn(seq, p, (STRLEN)(e - p));
		return;
	}
	while (p < e) {
		const char *run = p;
		while (p < e && !FASTA_SPACE(*p)) p++;
		if (p > run) sv_catpvn(seq, run, (STRLEN)(p - run));
		while (p < e && FASTA_SPACE(*p)) p++;
	}
}

/*Whether p..e holds nothing but whitespace.*/
static bool all_space(const char *p, const char *e) {
	for (; p < e; p++) {
		if (!FASTA_SPACE(*p)) return FALSE;
	}
	return TRUE;
}

/*Every record of fh as a hash of defline => sequence, or with key given only
that record's sequence (undef if it is absent), reading no further than the
defline after it. name is the file's name, for messages. order, when not NULL,
gets each defline in file order.

A repeated defline is warned about and its sequences concatenated, which is
what bioinf.pm did: it is the file that is wrong, and nothing here can say
which of the two records was meant. With key given, reading stops at the
defline after key's record, so the only repeat seen, and concatenated, is one
that follows it directly; a second record of key further on is never read,
and the one sequence returned is the first's alone. That is the price of
stopping early, and README.md says so. A repeat of any other defline is not
looked for either: finding it would mean keeping every defline read on the way
to key, a hash of 400,000 keys for one record of a proteome.

A defline with a CR inside it, once the whitespace at its end is gone, dies:
it is what a file whose lines end in CR alone (classic Mac OS) has, since with
no LF the whole file is one line, and up to 2026-11-10 such a file came back as
one record named by all of it, with no sequence. Biopython, which opens a file
in Python's universal-newlines mode, reads one; here it is refused, by one
memchr() a defline, rather than every CR being tested for as the file is
read.*/
static SV *read_fasta(pTHX_ PerlIO *fh, SV *key, const char *name, AV *order) {
	HV *out = (HV*)sv_2mortal((SV*)newHV());
	SV *hdr = sv_2mortal(newSVpvs(""));
	SV *seq = NULL;// record being filled; NULL before the first defline and while skipping
	bool have_def = FALSE, in_hdr = FALSE, bol = TRUE, done = FALSE, fed = FALSE;// fed: the '\n' that ends an unterminated last line has been supplied
	UV line = 0;// 1-based, as $. would count it
	char *restrict buf;
	Newx(buf, FASTA_BLOCK, char);
	SAVEFREEPV(buf);// freed at the caller's LEAVE, croak or not
	while (!done) {
		SSize_t n = PerlIO_read(fh, buf, FASTA_BLOCK);
		if (n < 0 || PerlIO_error(fh)) croak("%s: error reading %s: %s", __func__, name, Strerror(errno));
		if (n == 0) {
			if (bol || fed) break;
			buf[0] = '\n';
			n = 1;
			fed = 1;
		}
		const char *p = buf, *end = buf + n;
		while (p < end) {
			if (bol) {
				line++;
				bol = FALSE;
				if (*p == '>') {
					in_hdr = 1;
					SvCUR_set(hdr, 0);
					p++;
					continue;
				}
			}
			const char *nl = (const char*)memchr(p, '\n', (size_t)(end - p));
			const char *e = nl ? nl : end;
			if (in_hdr) sv_catpvn(hdr, p, (STRLEN)(e - p));
			else if (seq) cat_residues(aTHX_ seq, p, e);
			else if (!have_def && !all_space(p, e))
				croak("%s: %s line %" UVuf " is sequence, but no defline (\">...\") has come before it", __func__, name, line);
			if (!nl) break;
			p = nl + 1;
			bol = 1;
			if (!in_hdr) continue;
			in_hdr = FALSE;
			chop_space(hdr);
			if (!SvCUR(hdr)) croak("%s: %s line %" UVuf " is a defline with no name", __func__, name, line);
			if (memchr(SvPVX(hdr), '\r', SvCUR(hdr)))
				croak("%s: %s line %" UVuf " has a carriage return inside its defline, as a file whose lines end in CR alone (classic Mac OS) does; convert its line endings to LF first", __func__, name, line);
			if (seq) SvPV_shrink_to_cur(seq);
			bool is_key = key && sv_eq(hdr, key);
			if (key && !is_key && hv_exists_ent(out, key, 0)) {
				done = 1;// the wanted record is complete
				break;
			}
			have_def = 1;
			if (key && !is_key) {
				seq = NULL;
				continue;
			}
			if (hv_exists_ent(out, hdr, 0))
				warn("%s: \"%" SVf "\" appears more than once in %s (line %" UVuf "); its sequences will be concatenated", __func__, SVfARG(hdr), name, line);
			else if (order) av_push(order, newSVsv(hdr));
			seq = HeVAL(hv_fetch_ent(out, hdr, 1, 0));
			if (!SvOK(seq)) sv_setpvs(seq, "");
		}
	}
	if (seq) SvPV_shrink_to_cur(seq);
	if (!key) return newRV_inc((SV*)out);
	HE *he = hv_fetch_ent(out, key, 0, 0);
	return he ? SvREFCNT_inc_simple_NN(HeVAL(he)) : newSV(0);// not a copy: out is mortal, so this becomes the only reference
}

/*The bytes of sv for a FASTA file, as print to a :raw handle writes them: a
string perl holds as UTF-8 is written as the characters it holds, so that how
perl happened to store it cannot change the file. Up to 2026-10-17 it was
written as its UTF-8, and "caf\xe9" came out as one byte or two. scratch holds
that downgraded copy. A character above 255 has no byte, and gets NULL, for
the caller to die naming the string; print would write UTF-8 and warn.*/
static const char *fasta_bytes(pTHX_ SV *sv, SV *scratch, STRLEN *len) {
	if (SvUTF8(sv)) {
		sv_setsv(scratch, sv);
		if (!sv_utf8_downgrade(scratch, TRUE)) return NULL;
		sv = scratch;
	}
	return SvPV_const(sv, *len);
}

/*Each key of h named in order, as ">key" and then its sequence broken into
lines of width characters; width 0 puts each sequence on one line.

A key that is empty or holds a line feed dies, since read_fasta() could not
read its record back: the one is a defline with no name, and the other ends
the defline at the line feed and makes the rest of the key sequence. So does a
sequence that is a reference, unless it is an object that overloads its own
text. Up to 2026-11-10 all three were written, the reference as
"ARRAY(0x5ea732db32c8)".*/
static void write_fasta(pTHX_ PerlIO *fh, HV *h, AV *order, STRLEN width) {
	SV *kbuf = sv_newmortal(), *sbuf = sv_newmortal();// fasta_bytes()'s scratch copies, of the key and of its sequence
	for (SSize_t i = 0; i <= av_len(order); i++) {
		SV **k = av_fetch(order, i, 0);
		if (!k || !SvOK(*k)) croak("%s: element %" IVdf " of the order is undefined", __func__, (IV)i);
		HE *he = hv_fetch_ent(h, *k, 0, 0);
		STRLEN kl, sl;
		// kp and sp not restrict: a defline and its sequence may share one COW buffer
		const char *kp = fasta_bytes(aTHX_ *k, kbuf, &kl);
		if (!kp) croak("%s: \"%s\" has a character above 255, so it has to be encoded (with Encode::encode('UTF-8', ...), say) before it is written", __func__, SvPV_nolen(*k));
		if (!kl) croak("%s: element %" IVdf " of the order is an empty name, which a defline can't be", __func__, (IV)i);
		if (memchr(kp, '\n', kl)) croak("%s: \"%s\" has a line feed in it, which would end the defline there", __func__, kp);
		if (!he || !SvOK(HeVAL(he))) croak("%s: \"%s\" has no sequence in the hash", __func__, kp);
		if (SvROK(HeVAL(he)) && !SvAMAGIC(HeVAL(he))) croak("%s: the sequence of \"%s\" is a reference, not a string of residues", __func__, kp);
		const char *sp = fasta_bytes(aTHX_ HeVAL(he), sbuf, &sl);
		if (!sp) croak("%s: the sequence of \"%s\" has a character above 255, so it has to be encoded before it is written", __func__, kp);
		PerlIO_putc(fh, '>');
		PerlIO_write(fh, kp, kl);
		PerlIO_putc(fh, '\n');
		STRLEN w = width ? width : sl;
		for (STRLEN o = 0; o < sl; o += w) {
			PerlIO_write(fh, sp + o, sl - o < w ? sl - o : w);
			PerlIO_putc(fh, '\n');
		}
	}
	if (PerlIO_error(fh)) croak("%s: error writing FASTA: %s", __func__, Strerror(errno));
}

/*Building a FASTA index, samtools's .fai, for fasta_index() and fasta_region()
(since 2026-11-18; until then a perl readline loop in lib/Cn/Bioinf.pm's
_fai_scan, whose rules these are, line for line).

What is and is not a sequence that can be indexed is decided as fai_build_core()
of htslib 1.25's faidx.c decides it, and t/faidx.t checks the result against
that library's own expected index. A line is read in pieces, as the blocks
cut it, and only its length, the bytes of it that C's isgraph() takes, and its
first byte are kept; only a defline is copied, for its name. The index is
built as the .fai's own text, which fasta_index() writes as it is, rather than
as a perl array for each sequence. On a 305 MB file of 60 random sequences of
5 Mb in 60-column lines (2026-11-18, in the page cache, best of three), the
perl loop took 2.00 s and this 0.097 s, and the two indexes were identical.

Nothing croaks here. A file that cannot be indexed sets error, and the line
and name it concerns, for the perl side to word the message, which names the
public function the file was given to; a read error is one too.*/

/*Whether c is a base as fai_build_core() counts one: isgraph() in the C
locale, 0x21 '!' to 0x7e '~', 94 values in all.*/
#define FAI_GRAPH(c) ((unsigned char)((c) - 0x21) < 0x5e)

/*How many bytes of p..e FAI_GRAPH() takes, 8 at a time.

A word all of whose bytes are bases, which is nearly every word of a FASTA, is
counted whole: no byte below 0x21 is hasless(w, 0x21) and no byte above 0x7e
hasmore(w, 0x7e), from Sean Eron Anderson's "Bit Twiddling Hacks"
(graphics.stanford.edu/~seander/bithacks.html, sections HasLessInWord and
HasMoreInWord). Either may report a byte that is not there (a carry out of a
byte of 0xff reaches the next), but never misses one, so a word they flag is
merely counted a byte at a time. Counted a byte at a time throughout, the
file above took 0.22 s (gcc -O2 does not vectorize the loop).*/
static uint64_t fai_graph(const char *p, const char *e) {
	const uint64_t ones = UINT64_C(0x0101010101010101), high = ones * 0x80;
	uint64_t n = 0;
	for (; e - p >= 8; p += 8) {
		uint64_t w;
		memcpy(&w, p, 8);// not a cast to uint64_t *, since SPARC and some ARM fault on an unaligned load
		if (!(((w - ones * 0x21) & ~w & high) | (((w + ones) | w) & high))) {
			n += 8;
			continue;
		}
		for (unsigned short int k = 0; k < 8; k++) n += FAI_GRAPH(p[k]);
	}
	for (; p < e; p++) n += FAI_GRAPH(*p);
	return n;
}

/*The state of one scan. Positions and lengths are uint64_t, not UV, since a
32-bit perl (5.44.0-i686 here) has a 32-bit UV and a genome can be more than
4 GiB; perl's own arithmetic, which the readline loop used, went on in an NV.*/
typedef struct {
	SV *text;// the index so far, as .fai lines
	HV *seen;// the names indexed so far
	AV *dups;// each name met again after its first sequence, for the perl side to warn of
	SV *def;// the defline being read, its '>' gone
	SV *name;// the sequence being read: its defline's first word
	uint64_t pos;// bytes of the file before the line being read
	uint64_t line;// lines begun, counted from 1 as $. counts them
	uint64_t len;// bases of the sequence being read
	uint64_t offset;// where its first base is, in bytes
	uint64_t bases;// bases in each of its lines, from the first
	uint64_t width;// bytes in each of its lines, line ending included
	uint64_t ll;// bytes of the line being read so far, its '\n' left out
	uint64_t cl;// those of them FAI_GRAPH() takes
	char first;// the first byte of the line being read
	bool started;// a line has been begun and not yet ended
	bool named;// a defline has been read, so name is set
	bool inside;// TRUE = the sequence's lines are being read; FALSE = they have ended, and only a blank line or a defline may follow
	bool any;// the sequence has had a line, without which htslib does not count it as a sequence
	const char *error;// NULL, or why the file can't be indexed: "read", "no_sequence", "before_defline", "after_short", "longer" or "none"
	int read_errno;// errno when error is "read"; int, as C declares errno
} fai_state;

/*n as decimal digits onto sv. sv_catpvf()'s %" UVuf " cannot take a uint64_t
on a perl whose UV is 32 bits.*/
static void fai_cat_u64(pTHX_ SV *sv, uint64_t n) {
	char digits[20];// UINT64_MAX has 20
	unsigned short int k = 0;
	do {
		digits[k++] = (char)('0' + n % 10);
		n /= 10;
	} while (n);
	while (k) sv_catpvn(sv, &digits[--k], 1);
}

/*n as a perl number: a UV where one holds it, and an NV, exact to 2^53, where
it does not, as perl's own arithmetic would have it.*/
static SV *fai_number(pTHX_ uint64_t n) {
	return n <= (uint64_t)UV_MAX ? newSVuv((UV)n) : newSVnv((NV)n);
}

/*The sequence that has been read added to the index, or, when one of its name
is there already, to s->dups alone, since the first is the one indexed.*/
static void fai_add(pTHX_ fai_state *s) {
	if (hv_exists_ent(s->seen, s->name, 0)) {
		av_push(s->dups, newSVsv(s->name));
		return;
	}
	(void)hv_store_ent(s->seen, s->name, newSV(0), 0);
	sv_catsv(s->text, s->name);
	const uint64_t field[4] = { s->len, s->offset, s->bases, s->width };
	for (unsigned short int k = 0; k < 4; k++) {
		sv_catpvs(s->text, "\t");
		fai_cat_u64(aTHX_ s->text, field[k]);
	}
	sv_catpvs(s->text, "\n");
}

/*The line that has been read ended: by a '\n' when nl, and otherwise by the
end of the file.*/
static void fai_line(pTHX_ fai_state *s, bool nl) {
	s->started = FALSE;
	s->pos += s->ll + (nl ? 1 : 0);
	if (s->first == '>') {
		if (s->any) fai_add(aTHX_ s);
		if (!nl) {
			s->error = "no_sequence";
			return;
		}
		/*the name is the defline's first word, after any space that follows the
		'>'. FASTA_SPACE() is C's isspace() less the '\n' a defline cannot hold,
		which is what fai_build_core() tests (state IN_NAME, in the htslib source
		at ~/prog/htslib, 1.21-34-gb14fffb4, read on 2026-11-18); the perl loop's
		\s left '\v' out of it before perl 5.18.*/
		STRLEN dl;
		const char *d = SvPV_const(s->def, dl), *de = d + dl;// not restrict: perl's buffer
		while (d < de && FASTA_SPACE(*d)) d++;
		const char *w = d;
		while (w < de && !FASTA_SPACE(*w)) w++;
		sv_setpvn(s->name, d, (STRLEN)(w - d));
		s->named = TRUE;
		s->len = s->bases = s->width = 0;
		s->offset = s->pos;
		s->inside = TRUE;
		s->any = FALSE;
	} else if (s->inside && nl && s->ll == 0) {
		s->inside = FALSE;
	} else if (!s->inside) {
		if (nl && (s->ll == 0 || (s->ll == 1 && s->first == '\r'))) return;// a blank line, LF or CRLF
		s->error = s->named ? "after_short" : "before_defline";
	} else {
		/*the line's bytes with its line feed, which htslib counts even for a
		last line that has none*/
		const uint64_t width = s->ll + 1;
		s->any = TRUE;
		s->len += s->cl;
		if (s->width == 0) {
			s->width = width;
			s->bases = s->cl;
		} else if (width < s->width) {
			s->inside = FALSE;
		} else if (width > s->width) {
			s->error = "longer";
		}
	}
}

/*The FASTA fh scanned into s, whose text, seen, dups, def and name the caller
makes. buf is FASTA_BLOCK bytes.*/
static void fai_scan(pTHX_ PerlIO *fh, fai_state *s, char *restrict buf) {
	for (;;) {
		const SSize_t n = PerlIO_read(fh, buf, FASTA_BLOCK);
		if (n < 0 || PerlIO_error(fh)) {
			s->error = "read";
			s->read_errno = errno;
			return;
		}
		if (n == 0) break;
		const char *p = buf, *end = buf + n;
		while (p < end) {
			if (!s->started) {
				s->started = TRUE;
				s->line++;
				s->ll = s->cl = 0;
				s->first = *p;
				if (*p == '>') {
					SvCUR_set(s->def, 0);
					s->ll = 1;
					p++;
					continue;
				}
			}
			const char *nl = (const char*)memchr(p, '\n', (size_t)(end - p));
			const char *e = nl ? nl : end;
			if (s->first == '>') sv_catpvn(s->def, p, (STRLEN)(e - p));
			else s->cl += fai_graph(p, e);
			s->ll += (uint64_t)(e - p);
			if (!nl) break;
			p = nl + 1;
			fai_line(aTHX_ s, TRUE);
			if (s->error) return;
		}
	}
	if (s->started) {
		fai_line(aTHX_ s, FALSE);
		if (s->error) return;
	}
	if (!s->any) s->error = s->named ? "no_sequence" : "none";
	else fai_add(aTHX_ s);
}

/*Reading a VCF, for sex_check(), parent(), relatedness(), concordance(),
hirisplex_genotypes(), blood_type() and admixture().

The file is read by perl, which knows gzip and bzip2 through IO::Uncompress
(linking zlib and libbz2 here would be a build dependency on every platform),
and handed over a block at a time. vcf_read() cuts the blocks into lines and
gives each record to the reader's on_record, keeping nothing itself but the
one line a block can end inside; what each caller keeps is its own.*/

typedef struct vcf_reader vcf_reader;
struct vcf_reader {
	const char *name;// the file's, for messages
	UV line;// 1-based, as $. would count it
	UV min_depth;// a genotype whose DP is below this is not counted
	size_t n;// samples; 0 until the #CHROM line
	bool header;// the #CHROM line has been read
	bool stop;// set by on_header to read no further, as concordance() does to learn the truth's samples
	HV *samples;// sample => its 0-based column among the samples
	AV *names;// the samples in file order
	void (*on_header)(pTHX_ vcf_reader *r);// once the #CHROM line has been read
	void (*on_record)(pTHX_ vcf_reader *r, const char *p, const char *e);// each record, its '\n' gone
};

/*The end of the tab-separated field that starts at p, before e.*/
static const char *vcf_field_end(const char *p, const char *e) {
	const char *t = (const char*)memchr(p, '\t', (size_t)(e - p));
	return t ? t : e;
}

/*Sub-field k (0-based) of the colon-separated p..e, in *s..*f, or FALSE when
there are fewer.*/
static bool vcf_subfield(const char *p, const char *e, size_t k, const char **s, const char **f) {
	for (; k; k--) {
		p = (const char*)memchr(p, ':', (size_t)(e - p));
		if (!p) return FALSE;
		p++;
	}
	*s = p;
	const char *c = (const char*)memchr(p, ':', (size_t)(e - p));
	*f = c ? c : e;
	return TRUE;
}

/*The chromosome that CHROM p..f names, numbered as PLINK numbers them: 1 to
22, 23 for X and 24 for Y, and 0 for any other (MT, an unplaced contig). A
"chr" prefix, in any case, is dropped.*/
static unsigned short int vcf_chrom(const char *p, const char *f) {
	if (f - p > 3 && (p[0] == 'c' || p[0] == 'C') && (p[1] == 'h' || p[1] == 'H') && (p[2] == 'r' || p[2] == 'R')) p += 3;
	if (f - p == 1 && (*p == 'X' || *p == 'x')) return 23;
	if (f - p == 1 && (*p == 'Y' || *p == 'y')) return 24;
	if (f - p < 1 || f - p > 2 || *p < '1' || *p > '9') return 0;// "01" is not chromosome 1
	unsigned short int c = (unsigned short int)(*p - '0');
	if (f - p == 2) {
		if (p[1] < '0' || p[1] > '9') return 0;
		c = (unsigned short int)(c * 10 + (p[1] - '0'));
	}
	return c <= 24 ? c : 0;
}

/*The index of base c, 0 to 3 for A, C, G and T in either case, or 4 for
anything else.*/
static unsigned short int vcf_base_index(char c) {
	switch (c) {
		case 'A': case 'a': return 0;
		case 'C': case 'c': return 1;
		case 'G': case 'g': return 2;
		case 'T': case 't': return 3;
		default: return 4;
	}
}

/*Whether p..e is one base, as a SNV's REF and ALT are. An ALT of ".", "*" or
"<NON_REF>", or with a comma, is not.*/
static bool vcf_base(const char *p, const char *e) {
	return e - p == 1 && vcf_base_index(*p) < 4;
}

/*Where each of the 9 fixed columns of the record p..e starts, in col, given
that CHROM ends at f; returns where FORMAT ends, so that col[i + 1] - 1 ends
column i.*/
static const char *vcf_columns(pTHX_ const vcf_reader *r, const char *p, const char *f, const char *e, const char **col) {
	col[0] = p;
	for (unsigned short int i = 1; i < 9; i++) {
		if (f >= e) croak("%s: %s line %" UVuf " has %u columns, and a record needs 9 and a sample", __func__, r->name, r->line, (unsigned)i);
		col[i] = f + 1;
		f = vcf_field_end(col[i], e);
	}
	return f;
}

/*POS, the field p..f.*/
static UV vcf_pos(pTHX_ const vcf_reader *r, const char *p, const char *f) {
	if (p == f) croak("%s: %s line %" UVuf " has an empty POS", __func__, r->name, r->line);
	UV pos = 0;
	for (const char *q = p; q < f; q++) {
		if (*q < '0' || *q > '9' || pos > (UV_MAX - 9) / 10) croak("%s: %s line %" UVuf " has POS \"%.*s\", which isn't a position", __func__, r->name, r->line, (int)(f - p), p);
		pos = pos * 10 + (UV)(*q - '0');
	}
	return pos;
}

#define VCF_ABSENT ((size_t)-1) // a key that FORMAT doesn't name

/*GT's and DP's places in FORMAT, the field p..e, in *gt and *dp, or
VCF_ABSENT.*/
static void vcf_format(const char *p, const char *e, size_t *gt, size_t *dp) {
	*gt = *dp = VCF_ABSENT;
	size_t k = 0;
	for (const char *s = p; s <= e; k++) {
		const char *c = (const char*)memchr(s, ':', (size_t)(e - s));
		const char *ce = c ? c : e;
		if (ce - s == 2 && s[0] == 'G' && s[1] == 'T') *gt = k;
		else if (ce - s == 2 && s[0] == 'D' && s[1] == 'P') *dp = k;
		s = ce + 1;
	}
}

//What vcf_call() found
enum {
	VCF_SHALLOW, // a DP below min_depth: the genotype is not counted at all
	VCF_NO_CALL, // missing, partly missing ("./1"), cut short ("1/"), more than two alleles, or an allele the site lacks
	VCF_CALL     // one or two alleles, each REF or the one ALT
};

/*Whether the sample field p..e, whose FORMAT has DP at dp, has a DP below
r->min_depth. A DP that is absent, "." or not a whole number is not.*/
static bool vcf_shallow(const vcf_reader *r, const char *p, const char *e, size_t dp) {
	const char *s, *sf;
	if (dp == VCF_ABSENT || !vcf_subfield(p, e, dp, &s, &sf) || s == sf || *s == '.') return FALSE;
	UV depth = 0;
	for (; s < sf; s++) {
		if (*s < '0' || *s > '9' || depth > (UV_MAX - 9) / 10) return FALSE;
		depth = depth * 10 + (UV)(*s - '0');
	}
	return depth < r->min_depth;
}

/*The call in the sample field p..e of a biallelic site, whose FORMAT has GT
at gt and DP at dp: one of the values above, and for VCF_CALL the number of
alleles in *alleles and how many of them are the ALT in *alt. A DP that is
absent, "." or not a whole number leaves the genotype counted.*/
static short int vcf_call(const vcf_reader *r, const char *p, const char *e, size_t gt, size_t dp, unsigned short int *alleles, unsigned short int *alt) {
	const char *s, *sf;
	if (vcf_shallow(r, p, e, dp)) return VCF_SHALLOW;
	*alleles = *alt = 0;
	if (!vcf_subfield(p, e, gt, &s, &sf) || s == sf) return VCF_NO_CALL;
	while (s < sf) {
		if (++*alleles > 2 || *s == '.') return VCF_NO_CALL;
		if (*s == '1') ++*alt;
		else if (*s != '0') return VCF_NO_CALL;// no other allele exists at a biallelic site
		s++;
		if (s < sf) {
			if (*s != '/' && *s != '|') return VCF_NO_CALL;
			if (++s == sf) return VCF_NO_CALL;// "1/": a separator with no allele after it is a call cut short, not a haploid one
		}
	}
	return VCF_CALL;
}

/*The end of sample i's field, which starts at p; dies when the record ends
before it.*/
static const char *vcf_sample(pTHX_ const vcf_reader *r, const char *p, const char *e, size_t i) {
	if (p > e) croak("%s: %s line %" UVuf " has %" UVuf " samples, and the #CHROM line names %" UVuf, __func__, r->name, r->line, (UV)i, (UV)r->n);
	return vcf_field_end(p, e);
}

/*Dies when anything is left of the record after its last sample, which would
start at p.*/
static void vcf_samples_end(pTHX_ const vcf_reader *r, const char *p, const char *e) {
	if (p <= e) croak("%s: %s line %" UVuf " has more samples than the %" UVuf " its #CHROM line names", __func__, r->name, r->line, (UV)r->n);
}

/*The first 5 of names, quoted, and how many more there are, which is enough
to show how a VCF's samples are named; a mortal's PV.*/
static const char *vcf_names_list(pTHX_ AV *names) {
	SV *some = sv_2mortal(newSVpvs(""));
	const SSize_t last = av_len(names);
	for (SSize_t i = 0; i <= last && i < 5; i++) {
		SV **s = av_fetch(names, i, 0);
		sv_catpvf(some, "%s\"%s\"", i ? ", " : "", s ? SvPV_nolen(*s) : "");
	}
	if (last >= 5) sv_catpvf(some, " and %" UVuf " more", (UV)(last - 4));
	return SvPV_nolen(some);
}

/*The #CHROM line p..e: each sample after FORMAT gets its column in samples
and its place in names, and then the reader's on_header is called.*/
static void vcf_header(pTHX_ vcf_reader *r, const char *p, const char *e) {
	if (r->header) croak("%s: %s line %" UVuf " is a second #CHROM line", __func__, r->name, r->line);
	r->header = 1;
	unsigned short int col = 0;// columns passed; the samples start after the 9th, FORMAT
	while (p <= e && col < 9) {
		p = vcf_field_end(p, e) + 1;
		col++;
	}
	if (p > e) croak("%s: %s has no samples: its #CHROM line (line %" UVuf ") ends at %s", __func__, r->name, r->line, col < 9 ? "INFO or before" : "FORMAT");
	while (p <= e) {
		const char *f = vcf_field_end(p, e);
		// up to 2026-11-10 a tab at the end of the line made a sample named ""
		if (f == p) croak("%s: %s has an empty sample name in its #CHROM line (line %" UVuf "), column %" UVuf "; a tab at the end of the line, or two together, makes one", __func__, r->name, r->line, (UV)(r->n + 10));
		SV *name = newSVpvn(p, (STRLEN)(f - p));
		if (hv_exists_ent(r->samples, name, 0)) {
			// mortal on a line of its own: SvPV_nolen() is a macro that evaluates its
			// argument twice on perl 5.10.1 to 5.32.1, which then freed the name twice
			// ("Attempt to free unreferenced scalar"); 5.42.3 and 5.44.0 were unaffected
			sv_2mortal(name);
			const char *dup = SvPV_nolen(name);
			croak("%s: %s names sample \"%s\" twice in its #CHROM line", __func__, r->name, dup);
		}
		(void)hv_store_ent(r->samples, name, newSVuv((UV)r->n), 0);
		av_push(r->names, name);
		r->n++;
		p = f + 1;
	}
	if (r->on_header) r->on_header(aTHX_ r);
}

/*The line p..e, its '\n' gone.*/
static void vcf_line(pTHX_ vcf_reader *r, const char *p, const char *e) {
	r->line++;
	if (e > p && e[-1] == '\r') e--;
	if (p == e) return;
	if (*p != '#') {
		if (!r->header) croak("%s: %s line %" UVuf " is a record, but no #CHROM line has come before it", __func__, r->name, r->line);
		r->on_record(aTHX_ r, p, e);
	} else if (e - p >= 6 && memcmp(p, "#CHROM", 6) == 0) {
		vcf_header(aTHX_ r, p, e);
	}
}

/*The VCF r->name, which next, a perl sub, returns a block of at a time and
then undef. r's name, min_depth, on_header and on_record are the caller's to
set; the rest is set here.

next may grow perl's stack, which moves it, so an XSUB that reaches this must
PUTBACK before and SPAGAIN after, and push nothing with the SP it had on entry.
Up to 2026-10-26 none did, and a reader that grew the stack lost the results
or corrupted the heap ("realloc(): invalid next size"); t/checks.t grows it.*/
static void vcf_read(pTHX_ SV *next, vcf_reader *r) {
	r->line = 0;
	r->n = 0;
	r->header = FALSE;
	r->samples = (HV*)sv_2mortal((SV*)newHV());
	r->names = (AV*)sv_2mortal((SV*)newAV());
	SV *carry = sv_2mortal(newSVpvs(""));// the start of a line that the last block ended inside
	/*The block, copied out of the scope that next's own temporaries are freed
	with, so that whatever on_header saves for freeing (with SAVEFREEPV, say)
	lands in the caller's scope rather than that one; from perl 5.20 the copy
	is copy-on-write, and moves no bytes.*/
	SV *block = sv_newmortal();
	for (;;) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		PUTBACK;
		I32 got = call_sv(next, G_SCALAR);
		SPAGAIN;
		sv_setsv(block, got ? POPs : &PL_sv_undef);
		PUTBACK;
		FREETMPS;
		LEAVE;
		if (!SvOK(block) || r->stop) break;
		STRLEN n;
		const char *b = SvPV_const(block, n), *end = b + n;// not restrict: perl's buffer
		while (b < end && !r->stop) {
			const char *nl = (const char*)memchr(b, '\n', (size_t)(end - b));
			if (!nl) {
				sv_catpvn(carry, b, (STRLEN)(end - b));
				break;
			}
			if (SvCUR(carry)) {
				sv_catpvn(carry, b, (STRLEN)(nl - b));
				vcf_line(aTHX_ r, SvPVX_const(carry), SvPVX_const(carry) + SvCUR(carry));
				SvCUR_set(carry, 0);
			} else {
				vcf_line(aTHX_ r, b, nl);
			}
			b = nl + 1;
		}
	}
	if (SvCUR(carry) && !r->stop) vcf_line(aTHX_ r, SvPVX_const(carry), SvPVX_const(carry) + SvCUR(carry));
	if (!r->header) croak("%s: %s has no #CHROM line, so it isn't a VCF", __func__, r->name);
}

/*The genotype counts behind sex_check().

The method is peddy 0.4.3's sex_check() (peddy/peddy.py): on X outside its
pseudo-autosomal regions, count each sample's heterozygous and homozygous-ALT
calls at biallelic sites, leaving out a genotype whose depth is below a
minimum. Its PAR bounds, X:10000-2781479 and X:154931044-156030895, cover both
GRCh37's and GRCh38's, so no build need be named. It departs from peddy in
three ways. Every site is read, where peddy stops at 10,000. Only SNVs are
counted, where peddy keeps an insertion (its test is len(REF) > 1 alone). And
peddy's cohort filters (a call rate of at least 0.5, an ALT frequency of at
least 0.01) are left out, since they mean nothing for a VCF of one genome,
which is the usual input here.

Non-PAR Y is counted too, for the caller to see, but decides nothing: on
2026-10-18 the mother's exome, whose X is plainly female (2,592 het to 2,673
hom-ALT), had 530 called SNVs on non-PAR Y, and the father's exome had 659.
Y's PARs are GRCh37's (Y:10001-2649520, Y:59034050-59363566) and GRCh38's
(Y:10001-2781479, Y:56887903-57217415), from the GRC's assembly reports.

Nothing is kept but a fixed set of counters for each sample.*/

/*The counters kept for each sample, in this order in sex_tally's count; their
names in the hash returned to perl are SEX_NAME's.*/
enum { SEX_X_HET, SEX_X_HOM_ALT, SEX_X_HOM_REF, SEX_X_HAPLOID, SEX_X_MISSING, SEX_Y_CALLED, SEX_Y_ALT, SEX_FIELDS };
static const char *const SEX_NAME[SEX_FIELDS] = { "x_het", "x_hom_alt", "x_hom_ref", "x_haploid", "x_missing", "y_called", "y_alt" };

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * that sex_header() and sex_record() are given is this
	UV x_sites;// non-PAR X SNVs read, for perl to say when there were none
	UV *count;// r.n * SEX_FIELDS counters, sample by sample
} sex_tally;

/*Whether pos on chrom (23 for X, 24 for Y) lies in a pseudo-autosomal
region; see the comment above SEX_NAME for the bounds.*/
static bool sex_par(unsigned short int chrom, UV pos) {
	if (chrom == 23) return (pos >= 10000 && pos <= 2781479) || (pos >= 154931044 && pos <= 156030895);
	return (pos >= 10001 && pos <= 2781479) || (pos >= 56887903 && pos <= 57217415) || (pos >= 59034050 && pos <= 59363566);
}

/*Each sample's counters, once the #CHROM line has said how many samples
there are.*/
static void sex_header(pTHX_ vcf_reader *r) {
	sex_tally *t = (sex_tally*)r;
	Newxz(t->count, r->n * SEX_FIELDS, UV);
	SAVEFREEPV(t->count);// freed at the caller's LEAVE, croak or not; see vcf_read()'s block
}

/*Whether the record of chrom (23 for X, 24 for Y), whose columns vcf_columns()
put in col, is one that sex counts: outside the PARs, a biallelic SNV, and with
GT, whose place in FORMAT goes in *gt and DP's in *dp. format_end is
vcf_columns()'s.*/
static bool sex_site(pTHX_ const vcf_reader *r, unsigned short int chrom, const char **col, const char *format_end, size_t *gt, size_t *dp) {
	UV pos = vcf_pos(aTHX_ r, col[1], col[2] - 1);
	if (sex_par(chrom, pos) || !vcf_base(col[3], col[4] - 1) || !vcf_base(col[4], col[5] - 1)) return FALSE;
	vcf_format(col[8], format_end, gt, dp);
	return *gt != VCF_ABSENT;
}

/*One sample's call, the field p..e, at a site of chrom that sex_site() took,
into c, the sample's SEX_FIELDS counters.*/
static void sex_count(const vcf_reader *r, UV *c, unsigned short int chrom, const char *p, const char *e, size_t gt, size_t dp) {
	unsigned short int alleles, alt;
	short int call = vcf_call(r, p, e, gt, dp, &alleles, &alt);
	if (call == VCF_SHALLOW) return;
	if (chrom == 24) {
		if (call == VCF_NO_CALL) return;
		c[SEX_Y_CALLED]++;
		if (alt) c[SEX_Y_ALT]++;
	} else if (call == VCF_NO_CALL) {
		c[SEX_X_MISSING]++;
	} else {
		if (alleles == 1) c[SEX_X_HAPLOID]++;
		// a haploid call is hom-ALT or hom-REF, as peddy's cyvcf2 counts it
		c[alt == 0 ? SEX_X_HOM_REF : alt == alleles ? SEX_X_HOM_ALT : SEX_X_HET]++;
	}
}

//The record p..e.*/
static void sex_record(pTHX_ vcf_reader *r, const char *p, const char *e) {
	sex_tally *t = (sex_tally*)r;
	const char *f = vcf_field_end(p, e);
	unsigned short int chrom = vcf_chrom(p, f);// only 23 (X) and 24 (Y) are read
	if (chrom != 23 && chrom != 24) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	size_t gt, dp;
	if (!sex_site(aTHX_ r, chrom, col, format_end, &gt, &dp)) return;
	if (chrom == 23) t->x_sites++;
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		sex_count(r, t->count + i * SEX_FIELDS, chrom, p, se, gt, dp);
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
}

/*The SEX_FIELDS counts in count of the n samples in names, each stored in out
as sample => hash of counts, in place of anything out held for it.*/
static void sex_rows(pTHX_ HV *out, AV *names, const UV *count, size_t n, const char *name) {
	for (size_t i = 0; i < n; i++) {
		SV **sample = av_fetch(names, (SSize_t)i, 0);
		if (!sample) croak("%s: sample %" UVuf " of %s has lost its name", __func__, (UV)i, name);// cannot happen: every sample read was pushed
		HV *row = newHV();
		for (unsigned short int k = 0; k < SEX_FIELDS; k++) (void)hv_store(row, SEX_NAME[k], (I32)strlen(SEX_NAME[k]), newSVuv(count[i * SEX_FIELDS + k]), 0);
		(void)hv_store_ent(out, *sample, newRV_noinc((SV*)row), 0);
	}
}

/*The counts of every sample of the VCF name, which next returns a block of
at a time. Returns sample => hash of counts, and sets *x_sites and *names,
the samples in file order, for the report.*/
static HV *sex_tally_vcf(pTHX_ SV *next, const char *name, UV min_depth, UV *x_sites, AV **names) {
	sex_tally t;
	Zero(&t, 1, sex_tally);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = sex_header;
	t.r.on_record = sex_record;
	vcf_read(aTHX_ next, &t.r);
	HV *out = t.r.samples;
	sex_rows(aTHX_ out, t.r.names, t.count, t.r.n, name);// in place of the columns vcf_header() stored
	*x_sites = t.x_sites;
	*names = t.r.names;
	return out;
}

/*The genotype counts behind parent(): how many autosomal biallelic SNVs the
child and the parent have with each pair of ALT counts, 0 to 2. perl takes
IBS0, IBS1, IBS2 and the KING-robust kinship from those nine numbers.

The two samples are either columns of one VCF, which is read a record at a
time and nothing kept but the nine counts, or each the one sample of its own
VCF. A VCF of one genome usually lists only the sites where its sample
carries an ALT allele, so that a site absent from it stands for hom-REF; the
two are then compared site by site, which takes each file's sites in memory,
8 bytes a site, sorted (by C89's qsort(), since the two files need not list
their chromosomes in the same order). A position is left out when either file
has more than one SNV there, a call that is not a diploid call of REF and
ALT, a DP below min_depth, or more than one ALT, or when the files give it
different REF or ALT alleles. A file that leaves out filtered sites, or
off-target ones, makes the comparison see hom-REF where the sample was never
called; perl's report gives the sites each file had alone, for that reason.*/

#define PARENT_NONE 3 // the code of a sample with no diploid call of REF and ALT, or a DP below min_depth

/*A site of an own VCF is one uint64_t, packed so that sorting the numbers
sorts the sites by chromosome and then position, and the sites at one
position share every bit from bit 7 up:

chromosome (1-22) << 39 | POS (32 bits) << 7 | REF << 5 | ALT << 2 | code

where REF and ALT are vcf_base_index()'s 0 to 3, ALT is 4 for a record of
more than one ALT, and code is the ALT count or PARENT_NONE.*/
#define PARENT_POS_SHIFT 7
#define PARENT_ALLELES(k) (((k) >> 2) & 0x1f) // REF and ALT together
#define PARENT_ALT(k) (((k) >> 2) & 7)
#define PARENT_CODE(k) ((unsigned short int)((k) & 3))

/*An own VCF's sites, in a holder that the scope's destructor frees, since
Renew() moves the array.*/
typedef struct {
	uint64_t *site;
	size_t n, room;// sites used and allocated
} parent_sites;

static void parent_sites_free(pTHX_ void *p) {
	parent_sites *s = (parent_sites*)p;
	Safefree(s->site);
	Safefree(s);
}

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * that the callbacks are given is this
	SV *want[2];// one VCF: the child's and the parent's sample names; unused for own VCFs
	size_t col[2];// one VCF: their columns among the samples
	UV t[9];// one VCF: t[3 * child + parent], sites by the two codes
	parent_sites *sites;// own VCF: the file's sites
} parent_reader;

//The code of the call in the sample field p..e: its ALT count, or PARENT_NONE
static unsigned short int parent_code(const vcf_reader *r, const char *p, const char *e, size_t gt, size_t dp) {
	unsigned short int alleles, alt;
	return vcf_call(r, p, e, gt, dp, &alleles, &alt) == VCF_CALL && alleles == 2 ? alt : PARENT_NONE;
}

//One VCF: where the child's and the parent's columns are.
static void parent_header_one(pTHX_ vcf_reader *r) {
	parent_reader *t = (parent_reader*)r;
	for (unsigned short int k = 0; k < 2; k++) {
		HE *he = hv_fetch_ent(r->samples, t->want[k], 0, 0);
		if (he) {
			t->col[k] = (size_t)SvUV(HeVAL(he));
			continue;
		}
		const char *want = SvPV_nolen(t->want[k]), *list = vcf_names_list(aTHX_ r->names);
		croak("%s: %s has no sample \"%s\"; its samples are %s", __func__, r->name, want, list);
	}
}

//One VCF: the record p..e.
static void parent_record_one(pTHX_ vcf_reader *r, const char *p, const char *e) {
	parent_reader *t = (parent_reader*)r;
	const char *f = vcf_field_end(p, e);
	unsigned short int chrom = vcf_chrom(p, f);
	if (chrom < 1 || chrom > 22) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	if (!vcf_base(col[3], col[4] - 1) || !vcf_base(col[4], col[5] - 1)) return;
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	if (gt == VCF_ABSENT) return;
	unsigned short int code[2] = { PARENT_NONE, PARENT_NONE };// the child's and the parent's
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		for (unsigned short int k = 0; k < 2; k++) {
			if (i == t->col[k]) code[k] = parent_code(r, p, se, gt, dp);
		}
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
	if (code[0] != PARENT_NONE && code[1] != PARENT_NONE) t->t[3 * code[0] + code[1]]++;
}

/*Own VCF: one sample, or it isn't.*/
static void parent_header_own(pTHX_ vcf_reader *r) {
	if (r->n != 1) croak("%s: %s has %" UVuf " samples, and a VCF given as \"child\" or \"parent\" must have one; give a VCF of several as \"vcf\", and the samples by name", __func__, r->name, (UV)r->n);
}

/*Own VCF: the record p..e, kept as a site.*/
static void parent_record_own(pTHX_ vcf_reader *r, const char *p, const char *e) {
	parent_reader *t = (parent_reader*)r;
	const char *f = vcf_field_end(p, e);
	unsigned short int chrom = vcf_chrom(p, f);
	if (chrom < 1 || chrom > 22) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	if (!vcf_base(col[3], col[4] - 1)) return;
	unsigned short int alt;// vcf_base_index()'s, or 4 for more than one ALT
	if (vcf_base(col[4], col[5] - 1)) alt = vcf_base_index(*col[4]);
	else if (memchr(col[4], ',', (size_t)(col[5] - 1 - col[4]))) alt = 4;
	else return;// an indel, or an ALT of "." or "<NON_REF>"
	UV pos = vcf_pos(aTHX_ r, col[1], col[2] - 1);
	if (pos > UINT32_MAX) croak("%s: %s line %" UVuf " has POS %" UVuf ", beyond the 4294967295 that parent can compare", __func__, r->name, r->line, pos);
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	p = format_end + 1;
	const char *se = vcf_sample(aTHX_ r, p, e, 0);
	vcf_samples_end(aTHX_ r, se + 1, e);
	unsigned short int code = alt == 4 || gt == VCF_ABSENT ? PARENT_NONE : parent_code(r, p, se, gt, dp);
	parent_sites *s = t->sites;
	if (s->n == s->room) {
		s->room = s->room ? 2 * s->room : 65536;// 512 KiB, a sixth of an exome's 280,000 records
		Renew(s->site, s->room, uint64_t);
	}
	s->site[s->n++] = (uint64_t)chrom << 39 | (uint64_t)pos << PARENT_POS_SHIFT | (uint64_t)vcf_base_index(*col[3]) << 5 | (uint64_t)alt << 2 | code;
}

static int parent_cmp(const void *a, const void *b) {
	const uint64_t x = *(const uint64_t*)a, y = *(const uint64_t*)b;
	return (x > y) - (x < y);
}

/*Own VCF: the sites of the VCF that next returns a block of at a time, read
by t, whose name, min_depth and callbacks the caller has set, sorted.*/
static parent_sites *parent_sites_read(pTHX_ parent_reader *t, SV *next) {
	Newxz(t->sites, 1, parent_sites);
	SAVEDESTRUCTOR_X(parent_sites_free, t->sites);// at the caller's LEAVE, croak or not
	vcf_read(aTHX_ next, &t->r);
	if (t->sites->n) qsort(t->sites->site, t->sites->n, sizeof *t->sites->site, parent_cmp);
	return t->sites;
}

/*Own VCF: the sites of the VCF name, which next returns a block of at a
time, sorted.*/
static parent_sites *parent_sites_vcf(pTHX_ SV *next, const char *name, UV min_depth) {
	parent_reader t;
	Zero(&t, 1, parent_reader);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = parent_header_own;
	t.r.on_record = parent_record_own;
	return parent_sites_read(aTHX_ &t, next);
}

/*The sites of the child's VCF, a, and of the parent's, b, both sorted, as t
counts them; in[0], in[1] and in[2] get the sites where either carries the
ALT that were in both files, in the child's alone, and in the parent's alone.
The rules are in the comment above PARENT_NONE.*/
static void parent_merge(const parent_sites *a, const parent_sites *b, UV *t, UV *in) {
	size_t i = 0, j = 0;
	while (i < a->n || j < b->n) {
		const uint64_t pa = i < a->n ? a->site[i] >> PARENT_POS_SHIFT : UINT64_MAX, pb = j < b->n ? b->site[j] >> PARENT_POS_SHIFT : UINT64_MAX;
		const uint64_t at = pa < pb ? pa : pb;// the position to compare
		size_t na = 0, nb = 0;// its sites in each file
		while (i + na < a->n && a->site[i + na] >> PARENT_POS_SHIFT == at) na++;
		while (j + nb < b->n && b->site[j + nb] >> PARENT_POS_SHIFT == at) nb++;
		const uint64_t ka = na ? a->site[i] : 0, kb = nb ? b->site[j] : 0;
		i += na;
		j += nb;
		if (na > 1 || nb > 1) continue;
		if (na && (PARENT_CODE(ka) == PARENT_NONE || PARENT_ALT(ka) == 4)) continue;
		if (nb && (PARENT_CODE(kb) == PARENT_NONE || PARENT_ALT(kb) == 4)) continue;
		if (na && nb && PARENT_ALLELES(ka) != PARENT_ALLELES(kb)) continue;
		const unsigned short int c = na ? PARENT_CODE(ka) : 0, p = nb ? PARENT_CODE(kb) : 0;// a site absent from a file is hom-REF there
		t[3 * c + p]++;
		if (c || p) in[na && nb ? 0 : na ? 1 : 2]++;
	}
}

/*The genotype counts behind relatedness(): for every pair of samples, what
parent() counts for one pair, and for every sample what sex_check() counts,
from the same reading, so that brothers can be told from a brother and a
sister.

The samples are either all those of one VCF, or each the one sample of a VCF
of its own. One VCF is read a record at a time and nothing kept but the
counts: each sample's call at an autosomal site sets a bit in one of three
words, for 0, 1 and 2 ALTs, and at the end of a block of 64 sites each pair's
counts are taken from those words by popcount, 8 per pair, where taking them a
site at a time would be 64 tests of the pair's two calls. Own VCFs are each
read into parent_sites, as parent() reads them, and all of them held, and
then merged in one pass, which applies parent_merge()'s rules to each pair.
The files are opened by perl one at a time, so that only one is open.

A pair's counts are REL_T UVs, in the order rel_pair() numbers the pairs: t[1]
to t[8] of parent(), the sites by the first sample's ALT count and then the
second's, flattened as t[3 * first + second] -- t[0], where both are hom-REF,
is not a site compared, and is not kept -- and then, for own VCFs, in[0] to
in[2] of parent_merge(): the sites in both files, in the first's alone and in
the second's alone. For one VCF those three are left 0 and perl fills them.*/
#define REL_T 11

/*The number of pair (i, j), i < j, of n samples, when they are taken in the
order (0, 1), (0, 2) .. (0, n - 1), (1, 2) ..*/
static size_t rel_pair(size_t n, size_t i, size_t j) {
	return i * (2 * n - i - 1) / 2 + (j - i - 1);
}

/*The pairs of n samples, which dies when their counters could not be
addressed.*/
static size_t rel_pairs(pTHX_ size_t n) {
	if (n < 2) return 0;
	if (n > ((size_t)-1 / sizeof(UV) / REL_T) / n) croak("%s: %" UVuf " samples make too many pairs to count", __func__, (UV)n);
	return n * (n - 1) / 2;
}

/*The 1 bits in w, by the SWAR count of Sean Eron Anderson's "Bit Twiddling
Hacks" (graphics.stanford.edu/~seander/bithacks.html, section
CountBitsSetParallel), which needs no compiler builtin and no POPCNT
instruction.*/
static unsigned short int rel_popcount(uint64_t w) {
	w -= (w >> 1) & UINT64_C(0x5555555555555555);
	w = (w & UINT64_C(0x3333333333333333)) + ((w >> 2) & UINT64_C(0x3333333333333333));
	w = (w + (w >> 4)) & UINT64_C(0x0f0f0f0f0f0f0f0f);
	return (unsigned short int)((w * UINT64_C(0x0101010101010101)) >> 56);
}

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * that the callbacks are given is this
	uint64_t *plane;// 3 words a sample: bit k of plane[3 * s + c] is set when sample s has c ALTs at the block's site k
	unsigned short int k;// the block's sites so far, 0 to 63
	UV *t;// REL_T counters a pair
	UV *sex;// SEX_FIELDS counters a sample
} rel_reader;

/*One VCF: its counters, once the #CHROM line has said how many samples there
are.*/
static void rel_header_one(pTHX_ vcf_reader *r) {
	rel_reader *t = (rel_reader*)r;
	if (r->n < 2) croak("%s: %s has 1 sample, and relatedness compares two or more; give each person's VCF, as relatedness($file, $file2)", __func__, r->name);
	size_t pairs = rel_pairs(aTHX_ r->n);
	Newxz(t->plane, 3 * r->n, uint64_t);
	SAVEFREEPV(t->plane);// these three at the caller's LEAVE, croak or not; see vcf_read()'s block
	Newxz(t->t, pairs * REL_T, UV);
	SAVEFREEPV(t->t);
	Newxz(t->sex, r->n * SEX_FIELDS, UV);
	SAVEFREEPV(t->sex);
}

/*One VCF: the block's sites added to every pair's counts, and the block
emptied.*/
static void rel_flush(rel_reader *t) {
	const size_t n = t->r.n;
	const uint64_t *pl = t->plane;
	UV *c = t->t;
	for (size_t i = 0; i + 1 < n; i++) {
		const uint64_t a0 = pl[3 * i], a1 = pl[3 * i + 1], a2 = pl[3 * i + 2];
		for (size_t j = i + 1; j < n; j++, c += REL_T) {
			const uint64_t *b = pl + 3 * j;
			c[0] += rel_popcount(a0 & b[1]);// c[3 * first + second - 1]
			c[1] += rel_popcount(a0 & b[2]);
			c[2] += rel_popcount(a1 & b[0]);
			c[3] += rel_popcount(a1 & b[1]);
			c[4] += rel_popcount(a1 & b[2]);
			c[5] += rel_popcount(a2 & b[0]);
			c[6] += rel_popcount(a2 & b[1]);
			c[7] += rel_popcount(a2 & b[2]);
		}
	}
	Zero(t->plane, 3 * n, uint64_t);
	t->k = 0;
}

/*One VCF: the record p..e, an autosomal site for the pairs or an X or Y one
for each sample's sex.*/
static void rel_record_one(pTHX_ vcf_reader *r, const char *p, const char *e) {
	rel_reader *t = (rel_reader*)r;
	const char *f = vcf_field_end(p, e);
	unsigned short int chrom = vcf_chrom(p, f);
	if (chrom == 0) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	size_t gt, dp;
	p = format_end + 1;
	if (chrom > 22) {
		if (!sex_site(aTHX_ r, chrom, col, format_end, &gt, &dp)) return;
		for (size_t i = 0; i < r->n; i++) {
			const char *se = vcf_sample(aTHX_ r, p, e, i);
			sex_count(r, t->sex + i * SEX_FIELDS, chrom, p, se, gt, dp);
			p = se + 1;
		}
		vcf_samples_end(aTHX_ r, p, e);
		return;
	}
	if (!vcf_base(col[3], col[4] - 1) || !vcf_base(col[4], col[5] - 1)) return;
	vcf_format(col[8], format_end, &gt, &dp);
	if (gt == VCF_ABSENT) return;
	const uint64_t bit = (uint64_t)1 << t->k;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		unsigned short int code = parent_code(r, p, se, gt, dp);
		if (code != PARENT_NONE) t->plane[3 * i + code] |= bit;
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
	if (++t->k == 64) rel_flush(t);
}

typedef struct {
	parent_reader p;// first, so that the vcf_reader * that the callbacks are given is this, and parent_record_own() can read it
	UV *sex;// the SEX_FIELDS counters of the file's one sample
	HV *seen;// every file's sample so far => that file's name
	AV *names;// every file's sample so far, in the files' order
} rel_own_reader;

/*Own VCF: one sample, or it isn't, and not one that an earlier file named.*/
static void rel_header_own(pTHX_ vcf_reader *r) {
	rel_own_reader *t = (rel_own_reader*)r;
	if (r->n != 1) croak("%s: %s has %" UVuf " samples, and each of several VCFs must have one; give a VCF of several samples alone, as relatedness($file)", __func__, r->name, (UV)r->n);
	SV **sample = av_fetch(r->names, 0, 0);
	if (!sample) croak("%s: the sample of %s has lost its name", __func__, r->name);// cannot happen: vcf_header() pushed it
	HE *he = hv_fetch_ent(t->seen, *sample, 0, 0);
	if (he) {
		const char *first = SvPV_nolen(HeVAL(he)), *name = SvPV_nolen(*sample);
		croak("%s: %s and %s both name their sample \"%s\"", __func__, first, r->name, name);
	}
	(void)hv_store_ent(t->seen, *sample, newSVpv(r->name, 0), 0);
	av_push(t->names, newSVsv(*sample));
}

/*Own VCF: the record p..e, counted for the sample's sex on X and Y and kept
as a site, as parent() keeps it, on the autosomes.*/
static void rel_record_own(pTHX_ vcf_reader *r, const char *p, const char *e) {
	const char *f = vcf_field_end(p, e);
	unsigned short int chrom = vcf_chrom(p, f);
	if (chrom != 23 && chrom != 24) {
		parent_record_own(aTHX_ r, p, e);
		return;
	}
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	size_t gt, dp;
	if (!sex_site(aTHX_ r, chrom, col, format_end, &gt, &dp)) return;
	p = format_end + 1;
	const char *se = vcf_sample(aTHX_ r, p, e, 0);
	vcf_samples_end(aTHX_ r, se + 1, e);
	sex_count(r, ((rel_own_reader*)r)->sex, chrom, p, se, gt, dp);
}

//What a file has at the position rel_merge() is comparing
enum {
	REL_ABSENT,   // no site: its sample is hom-REF there
	REL_PRESENT,  // one site, whose call counts
	REL_UNUSABLE  // more than one, a call that does not count, or more than one ALT: every pair with its sample leaves the position out
};

/*Own VCFs: the sites of the n files in s, each sorted, counted into t, pair by
pair, by parent_merge()'s rules. Each position is found by looking at every
file's next site, which is n steps, and then counted for each file that
carries the ALT there against every other file, so that a pair where both are
hom-REF costs nothing.*/
static void rel_merge(pTHX_ parent_sites *const *s, size_t n, UV *t) {
	size_t *at, *carrier;// each file's next site; the files that carry the ALT at this position
	uint64_t *key;// each file's site at this position, when REL_PRESENT
	unsigned short int *state;// each file's REL_ABSENT, REL_PRESENT or REL_UNUSABLE at this position
	Newxz(at, n, size_t);
	SAVEFREEPV(at);// these four at the caller's LEAVE, croak or not
	Newx(carrier, n, size_t);
	SAVEFREEPV(carrier);
	Newx(key, n, uint64_t);
	SAVEFREEPV(key);
	Newx(state, n, unsigned short int);
	SAVEFREEPV(state);
	for (;;) {
		uint64_t pos = UINT64_MAX;// the position to compare, as the sites' bits from PARENT_POS_SHIFT up
		for (size_t f = 0; f < n; f++) {
			if (at[f] < s[f]->n && s[f]->site[at[f]] >> PARENT_POS_SHIFT < pos) pos = s[f]->site[at[f]] >> PARENT_POS_SHIFT;
		}
		if (pos == UINT64_MAX) break;
		size_t m = 0;// carriers
		for (size_t f = 0; f < n; f++) {
			size_t k = 0;
			while (at[f] + k < s[f]->n && s[f]->site[at[f] + k] >> PARENT_POS_SHIFT == pos) k++;
			if (!k) {
				state[f] = REL_ABSENT;
				continue;
			}
			key[f] = s[f]->site[at[f]];
			at[f] += k;
			state[f] = k > 1 || PARENT_CODE(key[f]) == PARENT_NONE || PARENT_ALT(key[f]) == 4 ? REL_UNUSABLE : REL_PRESENT;
			if (state[f] == REL_PRESENT && PARENT_CODE(key[f])) carrier[m++] = f;
		}
		for (size_t q = 0; q < m; q++) {
			const size_t i = carrier[q];
			const unsigned short int ci = PARENT_CODE(key[i]);
			for (size_t j = 0; j < n; j++) {
				if (j == i || state[j] == REL_UNUSABLE) continue;
				const bool both = state[j] == REL_PRESENT;
				const unsigned short int cj = both ? PARENT_CODE(key[j]) : 0;// a site absent from a file is hom-REF there
				if (cj && j < i) continue;// counted when j was the carrier
				if (both && PARENT_ALLELES(key[i]) != PARENT_ALLELES(key[j])) continue;
				UV *c = t + REL_T * (i < j ? rel_pair(n, i, j) : rel_pair(n, j, i));
				c[i < j ? 3 * ci + cj - 1 : 3 * cj + ci - 1]++;
				c[8 + (both ? 0 : i < j ? 1 : 2)]++;
			}
		}
	}
}

/*The n samples' pair counters t as one string of UVs, for perl to unpack with
"J". For 1,000 samples, an array of a scalar per counter took 226 MB where
this takes 44 MB (2026-10-19).*/
static SV *rel_counts(pTHX_ const UV *t, size_t n) {
	return newSVpvn((const char*)t, rel_pairs(aTHX_ n) * REL_T * sizeof(UV));
}

/*The genotype comparison behind concordance().

The method is ~/Scripts/old/x.low_ram_local_concordance.pl's (its
assay_concordance(), concordance() and metrics(), as they stood on
2026-10-19), which compared each sample of a directory of test VCFs with the
same sample in a directory of truth VCFs. Every record of the test is compared,
sample by sample, with the truth's record of the same site, and a site that
the truth lacks is a no-call there; a site that the truth has and the test
lacks is not compared at all. Each comparison is one of the 45 kinds of
CONC_NAME, and the metrics are taken from their counts as metrics() took them.

It departs from that script where the script died or could not match:
- A site is CHROM, POS, REF and ALT. The script also took ID, so that "rs123"
in one file and "." in the other were two sites, and it dropped a "chr" from
the truth's CHROM alone, so that two files that both had one shared no site;
here "chr", in any case, is dropped from both.
- A call is compared as its alleles, in either order, so that "1/0", "0|1" and
"0/1" are one call; the script compared GT strings, and died on the first two.
- A call missing in both ("." and "./.") is concordant_no_call, where the
script made it discordant_no_call_to_no_call, a kind outside its 45.
- A partly missing call ("./1"), one of more than two alleles, and one whose
DP is below min_depth are each a no-call, where the script died on the first
two and had no min_depth.
- The metrics' true positives and true negatives are corrected, and a
discordance of two ALT-carrying calls is a false positive and a false
negative, as the comment above CONC_TP says.

The test is read first, and every site of it kept with its calls for the
samples compared, and then the truth is read a record at a time and looked up
among them. RAM thus goes with the test's sites, which for the usual input, a
panel against a genome, are the fewer, and a truth record that matches no
test site costs no more than finding its end.*/

//What one call is. The order is that of the classes' names, which CONC_NAME's kinds are sorted by
enum { CONC_HAPLOID_ALT, CONC_HAPLOID_REF, CONC_HET_ALT, CONC_HET_REF, CONC_HOM_ALT, CONC_HOM_REF, CONC_NO_CALL };

/*The kinds of comparison, truth first and then test, in the order and with the
names of the script's @concordance_types.*/
#define CONC_KINDS 45
static const char *const CONC_NAME[CONC_KINDS] = {
	"concordant_diploid_ref_to_haploid_ref", "concordant_haploid_alt", "concordant_haploid_alt_to_hom_alt",
	"concordant_haploid_ref", "concordant_haploid_ref_to_diploid_ref", "concordant_het_alt", "concordant_het_ref",
	"concordant_hom_alt", "concordant_hom_alt_to_diploid_alt", "concordant_hom_ref", "concordant_no_call",
	"discordant_haploid_alt_to_haploid_alt", "discordant_haploid_alt_to_haploid_ref", "discordant_haploid_alt_to_het_alt",
	"discordant_haploid_alt_to_het_ref", "discordant_haploid_alt_to_hom_alt", "discordant_haploid_alt_to_hom_ref",
	"discordant_haploid_ref_to_haploid_alt", "discordant_haploid_ref_to_het_alt", "discordant_haploid_ref_to_het_ref",
	"discordant_haploid_ref_to_hom_alt",
	"discordant_het_alt_to_haploid_alt", "discordant_het_alt_to_haploid_ref", "discordant_het_alt_to_het_alt",
	"discordant_het_alt_to_het_ref", "discordant_het_alt_to_hom_alt", "discordant_het_alt_to_hom_ref",
	"discordant_het_ref_to_haploid_alt", "discordant_het_ref_to_haploid_ref", "discordant_het_ref_to_het_alt",
	"discordant_het_ref_to_het_ref", "discordant_het_ref_to_hom_alt", "discordant_het_ref_to_hom_ref",
	"discordant_hom_alt_to_haploid_alt", "discordant_hom_alt_to_haploid_ref", "discordant_hom_alt_to_het_alt",
	"discordant_hom_alt_to_het_ref", "discordant_hom_alt_to_hom_alt", "discordant_hom_alt_to_hom_ref",
	"discordant_hom_ref_to_haploid_alt", "discordant_hom_ref_to_het_alt", "discordant_hom_ref_to_het_ref",
	"discordant_hom_ref_to_hom_alt",
	"gained_site", "lost_site"
};
//The kinds that conc_kind() names, as indexes into CONC_NAME
enum {
	CONC_DIPLOID_REF_TO_HAPLOID_REF = 0,
	CONC_HAPLOID_ALT_TO_HOM_ALT = 2,
	CONC_HAPLOID_REF_TO_DIPLOID_REF = 4,
	CONC_HOM_ALT_TO_DIPLOID_ALT = 8,
	CONC_DISCORDANT = 11, // the first discordant_ kind; every kind before it is concordant_
	CONC_GAINED = 43,     // the truth a no-call, the test not
	CONC_LOST = 44        // the test a no-call, the truth not
};
//concordant_<class>, by the class of the two calls, which are the same
static const unsigned short int CONC_SAME[7] = { 1, 3, 5, 6, 7, 9, 10 };
/*discordant_<truth's class>_to_<test's class>, by the two classes. -1 marks
the four pairs of reference calls, which are concordant whatever their
ploidy.*/
static const short int CONC_DIFFERENT[6][6] = {
	{ 11, 12, 13, 14, 15, 16 },
	{ 17, -1, 18, 19, 20, -1 },
	{ 21, 22, 23, 24, 25, 26 },
	{ 27, 28, 29, 30, 31, 32 },
	{ 33, 34, 35, 36, 37, 38 },
	{ 39, -1, 40, 41, 42, -1 }
};

/*The sets of kinds that metrics() summed, as bits of CONC_NAME's indexes,
written out so that the rule cannot drift with the names. Each is what the
script's regex picked out of @concordance_types, but for CONC_TP, CONC_TN and
CONC_MISMATCH, which correct it (since 2026-10-19):
- CONC_TP, the true positives, is every concordant kind whose call carries an
ALT. The script's /^conc\w+(?:alt|hom)/ took concordant_hom_ref, by the "hom"
in it, so that a hom-REF site counted as a true positive and a true negative
both, and it left out concordant_het_ref, the commonest true positive.
- CONC_TN, the true negatives, is every concordant kind of reference calls,
whatever the ploidy of either. The script's tn_site,
/^concordant_(?:hom|haploid)\w+ref$/, left out
concordant_diploid_ref_to_haploid_ref, the mirror of a kind it took; and its
tn_genotype was concordant_hom_ref alone, though CONC_FP_REF counts a
haploid-REF truth called otherwise, so that specificity gave no credit for a
haploid-REF truth called right, as on a male's X. Here tn_genotype is
tn_site.
- CONC_MISMATCH is every discordant kind where both calls carry an ALT (0/1
against 1/1, or 0/1 against 0/2), which the script counted in neither
fp_genotype, which was CONC_FP_REF alone, nor fn_genotype, which was
CONC_FN_REF alone, so that it changed no precision or recall. It is now in
both, as benchmarking tools count it: the test's call is wrong, and the
truth's is missed. Specificity still takes CONC_FP_REF alone, since only a
reference truth is a negative.*/
#define CONC_BIT(k) ((uint64_t)1 << (k))
#define CONC_TP (CONC_BIT(1) | CONC_BIT(2) | CONC_BIT(5) | CONC_BIT(6) | CONC_BIT(7) | CONC_BIT(8))
#define CONC_TN (CONC_BIT(0) | CONC_BIT(3) | CONC_BIT(4) | CONC_BIT(9))
#define CONC_FP_REF (CONC_BIT(17) | CONC_BIT(18) | CONC_BIT(19) | CONC_BIT(20) | CONC_BIT(39) | CONC_BIT(40) | CONC_BIT(41) | CONC_BIT(42)) // /^discordant_(haploid|hom)_ref_\w+/: a reference truth, the test carrying an ALT
#define CONC_FN_REF (CONC_BIT(12) | CONC_BIT(16) | CONC_BIT(22) | CONC_BIT(26) | CONC_BIT(28) | CONC_BIT(32) | CONC_BIT(34) | CONC_BIT(38)) // /^discordant_\w+_(?:hom|haploid)_ref$/: the truth carrying an ALT, a reference test
#define CONC_MISMATCH (CONC_BIT(11) | CONC_BIT(13) | CONC_BIT(14) | CONC_BIT(15) | CONC_BIT(21) | CONC_BIT(23) | CONC_BIT(24) | CONC_BIT(25) \
	| CONC_BIT(27) | CONC_BIT(29) | CONC_BIT(30) | CONC_BIT(31) | CONC_BIT(33) | CONC_BIT(35) | CONC_BIT(36) | CONC_BIT(37))
#define CONC_AGREE (CONC_BIT(CONC_DISCORDANT - 1) - 1)                                                  // /^concordant_\w+(?:alt|ref)$/: every concordant_ kind but concordant_no_call
#define CONC_CALLED (((CONC_BIT(CONC_GAINED) - 1) & ~CONC_BIT(CONC_DISCORDANT - 1)))                   // /(?:alt|ref)$/: every kind but concordant_no_call, gained_site and lost_site

/*One sample's call. Alleles are held in 16 bits, which keeps a call to 6
bytes, two of which each test site keeps for each sample compared; conc_gt()
dies on an allele above 65535, which no VCF of real data has.*/
typedef struct {
	uint16_t a, b;// the alleles, in GT's order; b is 0 for a haploid call
	unsigned char n;// 0 = no-call, 1 = haploid, 2 = diploid
	bool phased;// GT separated them with '|'
} conc_call;

/*A site of the test.*/
typedef struct {
	uint64_t hash;// conc_hash()'s, of CHROM, POS, REF and ALT
	UV pos;
	size_t text;// where its CHROM to ALT, as the test has them and ended by '\n', start in conc_store's text
	bool found;// the truth has it
} conc_site;

/*Everything the test's reading keeps and the truth's reading looks in, in a
holder that the scope's destructor frees, since Renew() moves the arrays.*/
typedef struct {
	char *text;// every site's CHROM to ALT, each ended by '\n'
	size_t text_n, text_room;
	conc_site *site;
	size_t n, room;// sites used and allocated
	size_t *slot;// an open-addressed table of the sites by hash: a site's index + 1, or 0 for an empty slot
	size_t slots;// 0, or a power of 2 at least twice n
	conc_call *call;// 2 * pairs a site: for each pair, the test's call and then the truth's
	size_t *hit;// the sites that one truth record matches
	size_t hit_room;
	conc_call *truth;// a truth record's calls, one a pair
	size_t pairs;// samples compared
	size_t *test_col;// each pair's column among the test's samples
	size_t *truth_col;// and among the truth's
	size_t *test_pair;// each test column's pair + 1, or 0 when it is not compared
	size_t *truth_pair;// each truth column's pair + 1, or 0
	size_t truth_n;// the truth's samples, as read before the test
	UV found;// test sites that the truth has
} conc_store;

static void conc_store_free(pTHX_ void *p) {
	conc_store *s = (conc_store*)p;
	Safefree(s->text);
	Safefree(s->site);
	Safefree(s->slot);
	Safefree(s->call);
	Safefree(s->hit);
	Safefree(s->truth);
	Safefree(s->test_col);
	Safefree(s->truth_col);
	Safefree(s->test_pair);
	Safefree(s->truth_pair);
	Safefree(s);
}

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * that the callbacks are given is this
	conc_store *s;
	AV *truth_names;// the test's reader: the truth's samples, in its order
} conc_reader;

/*CHROM p..f without a "chr" prefix, in any case, as vcf_chrom() drops it; the
start is returned.*/
static const char *conc_chrom(const char *p, const char *f) {
	if (f - p > 3 && (p[0] == 'c' || p[0] == 'C') && (p[1] == 'h' || p[1] == 'H') && (p[2] == 'r' || p[2] == 'R')) p += 3;
	return p;
}

/*FNV-1a, 64-bit (Fowler, Noll and Vo; www.isthe.com/chongo/tech/comp/fnv/,
read 2026-10-19), of the bytes p..e, continuing from h.*/
static uint64_t conc_fnv(uint64_t h, const char *p, const char *e) {
	for (; p < e; p++) {
		h ^= (unsigned char)*p;
		h *= UINT64_C(0x100000001b3);
	}
	return h;
}

/*The hash of a site: its CHROM (less "chr") c..cf, POS, REF r..rf and ALT
a..af, with a byte that no field holds between the fields, so that moving a
byte from one to the next changes it.*/
static uint64_t conc_hash(const char *c, const char *cf, UV pos, const char *r, const char *rf, const char *a, const char *af) {
	static const char tab = '\t';
	uint64_t h = conc_fnv(UINT64_C(0xcbf29ce484222325), c, cf);
	h = conc_fnv(h, &tab, &tab + 1);
	for (unsigned short int i = 0; i < 64; i += 8) { // POS's 8 bytes, low first, whatever the width of a UV
		const char byte = (char)(((uint64_t)pos >> i) & 0xff);
		h = conc_fnv(h, &byte, &byte + 1);
	}
	h = conc_fnv(h, r, rf);
	h = conc_fnv(h, &tab, &tab + 1);
	return conc_fnv(h, a, af);
}

/*Where each of the five fields of site k's text starts, in fld, with fld[5]
one past its '\n', so that fld[i + 1] - 1 ends field i. The text has its four
tabs and its '\n', as conc_record_test() stored it.*/
static void conc_fields(const conc_store *s, size_t k, const char **fld) {
	const char *e = s->text + s->text_n;
	fld[0] = s->text + s->site[k].text;
	for (unsigned short int i = 1; i < 5; i++) fld[i] = (const char*)memchr(fld[i - 1], '\t', (size_t)(e - fld[i - 1])) + 1;
	fld[5] = (const char*)memchr(fld[4], '\n', (size_t)(e - fld[4])) + 1;
}

/*Whether two byte ranges are equal.*/
static bool conc_eq(const char *p, const char *pe, const char *q, const char *qe) {
	return pe - p == qe - q && memcmp(p, q, (size_t)(pe - p)) == 0;
}

/*The call in the sample field p..e, whose FORMAT has GT at gt and DP at dp,
into *c. A GT that FORMAT lacks, an empty or missing one, a partly missing one
("./1"), one of more than two alleles, and a DP below min_depth are each a
no-call. Dies on a GT that is not one, naming the sample of column i.*/
static void conc_gt(pTHX_ const vcf_reader *r, const char *p, const char *e, size_t gt, size_t dp, size_t i, conc_call *c) {
	c->a = c->b = 0;
	c->n = 0;
	c->phased = FALSE;
	const char *s, *sf;
	if (gt == VCF_ABSENT || vcf_shallow(r, p, e, dp) || !vcf_subfield(p, e, gt, &s, &sf) || s == sf) return;
	const char *g = s;// GT, for messages
	UV allele[2] = { 0, 0 };
	size_t n = 0;// alleles
	bool missing = FALSE, phased = FALSE;
	for (;;) {
		UV v = 0;
		if (s < sf && *s == '.') {
			missing = TRUE;
			s++;
		} else {
			const char *d = s;
			for (; s < sf && *s >= '0' && *s <= '9'; s++) {
				v = v * 10 + (UV)(*s - '0');
				if (v > 65535) {
					SV **name = av_fetch(r->names, (SSize_t)i, 0);
					croak("%s: %s line %" UVuf " has GT \"%.*s\" for sample \"%s\", whose allele is beyond the 65535 that concordance can compare", __func__, r->name, r->line, (int)(sf - g), g, name ? SvPV_nolen(*name) : "");
				}
			}
			if (s == d) break;// not an allele: said below
		}
		if (n < 2) allele[n] = v;
		n++;
		if (s == sf) {
			if (missing || n > 2) return;
			c->n = (unsigned char)n;
			c->a = (uint16_t)allele[0];
			c->b = (uint16_t)allele[1];
			c->phased = phased;
			return;
		}
		if (*s == '|') phased = TRUE;
		else if (*s != '/') break;
		if (++s == sf) break;// "0/"
	}
	SV **name = av_fetch(r->names, (SSize_t)i, 0);
	croak("%s: %s line %" UVuf " has GT \"%.*s\" for sample \"%s\", which isn't a genotype", __func__, r->name, r->line, (int)(sf - g), g, name ? SvPV_nolen(*name) : "");
}

/*The class of call c.*/
static unsigned short int conc_class(const conc_call *c) {
	if (c->n == 0) return CONC_NO_CALL;
	if (c->n == 1) return c->a ? CONC_HAPLOID_ALT : CONC_HAPLOID_REF;
	if (c->a == c->b) return c->a ? CONC_HOM_ALT : CONC_HOM_REF;
	return c->a && c->b ? CONC_HET_ALT : CONC_HET_REF;
}

/*Whether two calls are the same: both no-calls, or of one ploidy with the same
alleles, in either order.*/
static bool conc_same(const conc_call *x, const conc_call *y) {
	if (x->n != y->n) return FALSE;
	if (x->n < 2) return x->a == y->a;
	return (x->a == y->a && x->b == y->b) || (x->a == y->b && x->b == y->a);
}

/*The kind of comparison, an index into CONC_NAME, of the truth's call and the
test's, by the script's assay_concordance(), in its order.*/
static unsigned short int conc_kind(const conc_call *truth, const conc_call *test) {
	const unsigned short int ct = conc_class(truth), cs = conc_class(test);
	if (conc_same(truth, test)) return CONC_SAME[ct];
	if (cs == CONC_NO_CALL) return CONC_LOST;// the truth is not, or the two would be the same
	if (ct == CONC_NO_CALL) return CONC_GAINED;
	if (ct == CONC_HOM_REF && cs == CONC_HAPLOID_REF) return CONC_DIPLOID_REF_TO_HAPLOID_REF;
	if (ct == CONC_HAPLOID_REF && cs == CONC_HOM_REF) return CONC_HAPLOID_REF_TO_DIPLOID_REF;
	if (ct == CONC_HOM_ALT && test->n == 1 && test->a == truth->a) return CONC_HOM_ALT_TO_DIPLOID_ALT;
	if (cs == CONC_HOM_ALT && truth->n == 1 && truth->a == test->a) return CONC_HAPLOID_ALT_TO_HOM_ALT;
	return (unsigned short int)CONC_DIFFERENT[ct][cs];// never -1: those four pairs were taken above
}

/*Call c as GT would write it, a mortal: "." for a no-call.*/
static SV *conc_call_sv(pTHX_ const conc_call *c) {
	if (c->n == 0) return sv_2mortal(newSVpvs("."));
	if (c->n == 1) return sv_2mortal(newSVpvf("%u", (unsigned)c->a));
	return sv_2mortal(newSVpvf("%u%c%u", (unsigned)c->a, c->phased ? '|' : '/', (unsigned)c->b));
}

/*The test's #CHROM line: the pairs of samples to compare. Two VCFs of one
sample each are compared whatever their samples are called; otherwise each of
the test's samples is compared with the truth's of the same name.*/
static void conc_header_test(pTHX_ vcf_reader *r) {
	conc_reader *t = (conc_reader*)r;
	conc_store *s = t->s;
	Newxz(s->test_col, r->n, size_t);
	Newxz(s->truth_col, r->n, size_t);
	Newxz(s->test_pair, r->n, size_t);
	Newxz(s->truth_pair, s->truth_n, size_t);
	if (r->n == 1 && s->truth_n == 1) {
		s->pairs = 1;
		s->test_pair[0] = s->truth_pair[0] = 1;
	} else {
		HV *truth = (HV*)sv_2mortal((SV*)newHV());// the truth's sample => its column
		for (size_t j = 0; j < s->truth_n; j++) {
			SV **name = av_fetch(t->truth_names, (SSize_t)j, 0);
			if (name) (void)hv_store_ent(truth, *name, newSVuv((UV)j), 0);
		}
		for (size_t i = 0; i < r->n; i++) {
			SV **name = av_fetch(r->names, (SSize_t)i, 0);
			HE *he = name ? hv_fetch_ent(truth, *name, 0, 0) : NULL;
			if (!he) continue;
			const size_t j = (size_t)SvUV(HeVAL(he));
			s->test_col[s->pairs] = i;
			s->truth_col[s->pairs] = j;
			s->test_pair[i] = s->truth_pair[j] = ++s->pairs;
		}
	}
	if (!s->pairs) {
		const char *test = vcf_names_list(aTHX_ r->names), *truth = vcf_names_list(aTHX_ t->truth_names);
		croak("%s: %s and the truth share no sample: the test's are %s, and the truth's %s", __func__, r->name, test, truth);
	}
	Newx(s->truth, s->pairs, conc_call);
}

/*Room for one more site of the test r, its calls, and a slot in the table,
which is rebuilt at twice the size when it would be more than half full. Dies,
naming r, when the calls' size would not fit in a size_t: on a 32-bit perl,
349,526 samples or more do at the first 1,024 sites. Renew() checks only the
multiplication by the type's size, and only on a perl built with
usemallocwrap (the default), where it died with "panic: memory wrap", naming
nothing; on one built without, the calls were allocated too small.*/
static void conc_grow(pTHX_ const vcf_reader *r, conc_store *s) {
	if (s->n == s->room) {
		const size_t room = s->room ? 2 * s->room : 1024;// small, since its calls are 12 bytes a pair each: 1,000 samples start at 12 MB
		if (room < s->room || room > ((size_t)-1 / sizeof(conc_call) / 2) / s->pairs)
			croak("%s: %s has more sites of its %" UVuf " samples compared than this perl can hold (%" UVuf " already)", __func__, r->name, (UV)s->pairs, (UV)s->n);
		s->room = room;
		Renew(s->site, s->room, conc_site);
		Renew(s->call, s->room * 2 * s->pairs, conc_call);
	}
	if (2 * (s->n + 1) <= s->slots) return;
	s->slots = s->slots ? 2 * s->slots : 2048;
	Safefree(s->slot);
	Newxz(s->slot, s->slots, size_t);
	for (size_t k = 0; k < s->n; k++) {
		size_t at = (size_t)s->site[k].hash & (s->slots - 1);
		while (s->slot[at]) at = (at + 1) & (s->slots - 1);
		s->slot[at] = k + 1;
	}
}

/*The test's record p..e, kept as a site with its calls for each pair. A site
the test lists twice is kept twice, and each compared, as the script compared
each line.*/
static void conc_record_test(pTHX_ vcf_reader *r, const char *p, const char *e) {
	conc_store *s = ((conc_reader*)r)->s;
	const char *f = vcf_field_end(p, e);
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	conc_grow(aTHX_ r, s);
	conc_site *site = s->site + s->n;
	site->pos = vcf_pos(aTHX_ r, col[1], col[2] - 1);
	const char *chrom = conc_chrom(col[0], col[1] - 1);
	site->hash = conc_hash(chrom, col[1] - 1, site->pos, col[3], col[4] - 1, col[4], col[5] - 1);
	site->found = FALSE;
	const size_t len = (size_t)(col[5] - p);// CHROM to ALT, and the tab after ALT, which becomes the '\n'
	if (s->text_n + len > s->text_room) {
		while (s->text_n + len > s->text_room) {
			if (s->text_room > (size_t)-1 / 2) croak("%s: %s has more sites than this perl can hold (%" UVuf " already)", __func__, r->name, (UV)s->n);// doubling would wrap to 0, and loop for ever
			s->text_room = s->text_room ? 2 * s->text_room : 1 << 20;
		}
		Renew(s->text, s->text_room, char);
	}
	site->text = s->text_n;
	Copy(p, s->text + s->text_n, len, char);
	s->text_n += len;
	s->text[s->text_n - 1] = '\n';
	size_t at = (size_t)site->hash & (s->slots - 1);
	while (s->slot[at]) at = (at + 1) & (s->slots - 1);
	s->slot[at] = ++s->n;
	conc_call *call = s->call + (s->n - 1) * 2 * s->pairs;
	Zero(call, 2 * s->pairs, conc_call);// the truth's calls stay no-calls unless it has the site
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		if (s->test_pair[i]) conc_gt(aTHX_ r, p, se, gt, dp, i, call + 2 * (s->test_pair[i] - 1));
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
}

/*The truth's #CHROM line, which must be the one read before the test was.*/
static void conc_header_truth(pTHX_ vcf_reader *r) {
	conc_store *s = ((conc_reader*)r)->s;
	if (r->n != s->truth_n) croak("%s: %s had %" UVuf " samples when it was first read, and has %" UVuf " now", __func__, r->name, (UV)s->truth_n, (UV)r->n);
}

/*The truth's record p..e: its calls for each pair, given to every test site
that it is. A site the truth lists twice gives the test its last calls, as the
script's hash of the truth's sites did.*/
static void conc_record_truth(pTHX_ vcf_reader *r, const char *p, const char *e) {
	conc_store *s = ((conc_reader*)r)->s;
	if (!s->slots) return;// the test has no sites
	const char *f = vcf_field_end(p, e);
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	const UV pos = vcf_pos(aTHX_ r, col[1], col[2] - 1);
	const char *chrom = conc_chrom(col[0], col[1] - 1);
	const uint64_t hash = conc_hash(chrom, col[1] - 1, pos, col[3], col[4] - 1, col[4], col[5] - 1);
	size_t hits = 0;
	for (size_t at = (size_t)hash & (s->slots - 1); s->slot[at]; at = (at + 1) & (s->slots - 1)) {
		const size_t k = s->slot[at] - 1;
		const conc_site *site = s->site + k;
		if (site->hash != hash || site->pos != pos) continue;
		const char *fld[6];
		conc_fields(s, k, fld);
		if (!conc_eq(conc_chrom(fld[0], fld[1] - 1), fld[1] - 1, chrom, col[1] - 1) || !conc_eq(fld[3], fld[4] - 1, col[3], col[4] - 1)
			|| !conc_eq(fld[4], fld[5] - 1, col[4], col[5] - 1)) continue;
		if (hits == s->hit_room) {
			s->hit_room = s->hit_room ? 2 * s->hit_room : 8;// a site the test lists more than once, which is rare
			Renew(s->hit, s->hit_room, size_t);
		}
		s->hit[hits++] = k;
	}
	if (!hits) return;
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		if (s->truth_pair[i]) conc_gt(aTHX_ r, p, se, gt, dp, i, s->truth + (s->truth_pair[i] - 1));
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
	for (size_t h = 0; h < hits; h++) {
		conc_site *site = s->site + s->hit[h];
		if (!site->found) s->found++;
		site->found = TRUE;
		conc_call *call = s->call + s->hit[h] * 2 * s->pairs;
		for (size_t k = 0; k < s->pairs; k++) call[2 * k + 1] = s->truth[k];
	}
}

/*The sum of the counts c of the kinds in set, CONC_BIT()s.*/
static UV conc_sum(const UV *c, uint64_t set) {
	UV sum = 0;
	for (unsigned short int k = 0; k < CONC_KINDS; k++) {
		if (set & CONC_BIT(k)) sum += c[k];
	}
	return sum;
}

/*x / y as a mortal, or undef when y is 0, where the script gave the string
"undefined" (and, for genotype_concordance, died).*/
static SV *conc_ratio(pTHX_ UV x, UV y) {
	return y ? sv_2mortal(newSVnv((NV)x / (NV)y)) : sv_newmortal();
}

static void conc_store_sv(pTHX_ HV *h, const char *key, SV *v) {
	(void)hv_store(h, key, (I32)strlen(key), SvREFCNT_inc_simple_NN(v), 0);
}

/*The metrics of counts c, by the script's metrics() called as its main
program called it, with no-calls left out ("no"), and with the corrections
given above CONC_TP.*/
static HV *conc_metrics(pTHX_ const UV *c) {
	HV *m = newHV();
	const UV tp = conc_sum(c, CONC_TP), fp_site = c[CONC_GAINED], fn_site = c[CONC_LOST];
	const UV fp_ref = conc_sum(c, CONC_FP_REF), mismatch = conc_sum(c, CONC_MISMATCH);
	const UV fp_genotype = fp_ref + mismatch, fn_genotype = conc_sum(c, CONC_FN_REF) + mismatch;
	const UV tn = conc_sum(c, CONC_TN);
	conc_store_sv(aTHX_ m, "tp_site", sv_2mortal(newSVuv(tp)));
	conc_store_sv(aTHX_ m, "fp_site", sv_2mortal(newSVuv(fp_site)));
	conc_store_sv(aTHX_ m, "fn_site", sv_2mortal(newSVuv(fn_site)));
	conc_store_sv(aTHX_ m, "tn_site", sv_2mortal(newSVuv(tn)));
	conc_store_sv(aTHX_ m, "tp_genotype", sv_2mortal(newSVuv(tp)));
	conc_store_sv(aTHX_ m, "fp_genotype", sv_2mortal(newSVuv(fp_genotype)));
	conc_store_sv(aTHX_ m, "fn_genotype", sv_2mortal(newSVuv(fn_genotype)));
	conc_store_sv(aTHX_ m, "tn_genotype", sv_2mortal(newSVuv(tn)));
	conc_store_sv(aTHX_ m, "genotype_concordance", conc_ratio(aTHX_ conc_sum(c, CONC_AGREE), conc_sum(c, CONC_CALLED)));
	conc_store_sv(aTHX_ m, "precision_site", conc_ratio(aTHX_ tp, tp + fp_site));
	conc_store_sv(aTHX_ m, "recall_site", conc_ratio(aTHX_ tp, tp + fn_site));
	conc_store_sv(aTHX_ m, "precision_genotype", conc_ratio(aTHX_ tp, tp + fp_genotype));
	conc_store_sv(aTHX_ m, "recall_genotype", conc_ratio(aTHX_ tp, tp + fn_genotype));
	conc_store_sv(aTHX_ m, "specificity_genotype", conc_ratio(aTHX_ tn, tn + fp_ref));
	return m;
}

/*Each pair's results, keyed by the test's name for its sample, from the test
and truth names, the sites s holds, and whether to list the discordant,
gained and lost ones.*/
static HV *conc_results(pTHX_ const conc_store *s, AV *test_names, AV *truth_names, bool discordances) {
	UV *count;// CONC_KINDS a pair
	Newxz(count, s->pairs * CONC_KINDS, UV);
	SAVEFREEPV(count);
	AV **list;// each pair's discordances, or NULL
	Newxz(list, s->pairs, AV*);
	SAVEFREEPV(list);
	for (size_t k = 0; k < s->pairs && discordances; k++) list[k] = (AV*)sv_2mortal((SV*)newAV());
	for (size_t i = 0; i < s->n; i++) {
		const conc_call *call = s->call + i * 2 * s->pairs;
		const char *fld[6];
		bool split = FALSE;// fld has been set
		for (size_t k = 0; k < s->pairs; k++) {
			const unsigned short int kind = conc_kind(call + 2 * k + 1, call + 2 * k);
			count[k * CONC_KINDS + kind]++;
			if (!list[k] || kind < CONC_DISCORDANT) continue;
			if (!split) {
				conc_fields(s, i, fld);
				split = TRUE;
			}
			HV *row = newHV();
			conc_store_sv(aTHX_ row, "chrom", sv_2mortal(newSVpvn(fld[0], (STRLEN)(fld[1] - 1 - fld[0]))));
			conc_store_sv(aTHX_ row, "pos", sv_2mortal(newSVuv(s->site[i].pos)));
			conc_store_sv(aTHX_ row, "id", sv_2mortal(newSVpvn(fld[2], (STRLEN)(fld[3] - 1 - fld[2]))));
			conc_store_sv(aTHX_ row, "ref", sv_2mortal(newSVpvn(fld[3], (STRLEN)(fld[4] - 1 - fld[3]))));
			conc_store_sv(aTHX_ row, "alt", sv_2mortal(newSVpvn(fld[4], (STRLEN)(fld[5] - 1 - fld[4]))));
			conc_store_sv(aTHX_ row, "type", sv_2mortal(newSVpvn(CONC_NAME[kind], strlen(CONC_NAME[kind]))));
			conc_store_sv(aTHX_ row, "test", conc_call_sv(aTHX_ call + 2 * k));
			conc_store_sv(aTHX_ row, "truth", conc_call_sv(aTHX_ call + 2 * k + 1));
			av_push(list[k], newRV_noinc((SV*)row));
		}
	}
	HV *out = (HV*)sv_2mortal((SV*)newHV());
	for (size_t k = 0; k < s->pairs; k++) {
		SV **test = av_fetch(test_names, (SSize_t)s->test_col[k], 0), **truth = av_fetch(truth_names, (SSize_t)s->truth_col[k], 0);
		if (!test || !truth) croak("%s: pair %" UVuf " has lost a sample's name", __func__, (UV)k);// cannot happen: both headers pushed every name
		const UV *c = count + k * CONC_KINDS;
		HV *pair = newHV();
		HV *counts = newHV();
		for (unsigned short int j = 0; j < CONC_KINDS; j++) (void)hv_store(counts, CONC_NAME[j], (I32)strlen(CONC_NAME[j]), newSVuv(c[j]), 0);
		conc_store_sv(aTHX_ pair, "test_sample", sv_2mortal(newSVsv(*test)));
		conc_store_sv(aTHX_ pair, "truth_sample", sv_2mortal(newSVsv(*truth)));
		conc_store_sv(aTHX_ pair, "sites", sv_2mortal(newSVuv((UV)s->n)));
		conc_store_sv(aTHX_ pair, "in_truth", sv_2mortal(newSVuv(s->found)));
		(void)hv_store(pair, "counts", 6, newRV_noinc((SV*)counts), 0);
		(void)hv_store(pair, "metrics", 7, newRV_noinc((SV*)conc_metrics(aTHX_ c)), 0);
		(void)hv_store(pair, "discordances", 12, list[k] ? newRV_inc((SV*)list[k]) : newSV(0), 0);
		(void)hv_store_ent(out, *test, newRV_noinc((SV*)pair), 0);
	}
	return out;
}

/*An on_header that reads no further, and an on_record that is never called
after it, for _vcf_samples(), which reads only the #CHROM line.*/
static void conc_stop(pTHX_ vcf_reader *r) {
	r->stop = TRUE;
}

static void conc_skip(pTHX_ vcf_reader *r, const char *p, const char *e) {
	PERL_UNUSED_ARG(r);
	PERL_UNUSED_ARG(p);
	PERL_UNUSED_ARG(e);
}

/*The genotypes of a marker panel, for hirisplex_genotypes().

The panel is 41 markers and a VCF of a whole genome is tens of millions of
records, so each record is tested against the panel rather than the panel
searched for in the file. Matching by position tests the chromosome against a
bitmap first, which turns away a record on one test, and reads POS and
searches only when that passes; matching by ID compares the ID column against
the markers' rs numbers. Either way a record that matches nothing is read no
further than its first three fields.

Which allele is counted is perl's to say, from share/hirisplex_s_panel.tsv:
the panel names the allele on the forward strand, so nothing here complements
anything. The allele is looked for among REF and the ALTs, and its place
there is what the genotypes are counted against, so that a site written with
several ALTs, or with the counted allele as its REF, is counted the same way.
A record whose REF is longer than one base is passed over for every marker but
the one that is an indel, since it is some other variant that shares the
position. That one, an insertion, is counted from the ALT that is REF with its
base put in once, which is the same test however the VCF anchors the indel.
Bases are compared regardless of case, as CHROM is.

What is kept is one byte for each sample at each marker, so a file costs one
byte times its samples times the panel, however many records it holds.*/

#define HPS_ID 16 // an rs number and its NUL; the longest the panel holds is "rs796296176", 11 characters

//What hps_dose() gives for a sample at a marker; 0, 1 and 2 are counts of the counted allele
enum {
	HPS_ABSENT  = 3, // no record of the marker was in the file; set for every sample before reading
	HPS_NO_CALL = 4  // the marker was in the file, and this sample had no diploid call of it
};

typedef struct {
	unsigned short int chrom;// vcf_chrom()'s numbering, 1 to 24; 0 when the panel gives no position
	UV pos;
	char allele;// the base counted, or the base inserted when insertion is TRUE
	bool insertion;// TRUE = count the ALT that is REF with allele put in once, for the one marker of the panel that is an indel
	size_t k;// the marker's place in the panel perl gave, which its genotypes are stored under
	char id[HPS_ID];// the marker's rs number, for matching by ID
} hps_site;

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * hps_header() and hps_record() are given is this
	hps_site *site;// what is searched, sorted by chromosome and position, or by rs number when by_id
	size_t entries;// how many site's holds, which is more than sites when a marker is searched for under more than one rs number
	size_t sites;// markers in the panel, which is what each sample's genotypes are counted into
	bool by_id;// TRUE = match the ID column, FALSE = CHROM and POS
	uint32_t chroms;// bit c set for each chromosome c the panel uses, tested before POS is read
	unsigned char *dose;// r.n * sites, sample-major: a count, or one of the codes above
	bool *seen;// one per marker: the file held a record for it
	bool *carried;// one per marker: a record of it held the counted allele among REF and the ALTs
} hps_reader;

/*Orders the panel by chromosome and position, for hps_find().*/
static int hps_cmp_pos(const void *a, const void *b) {
	const hps_site *x = (const hps_site*)a, *y = (const hps_site*)b;
	if (x->chrom != y->chrom) return x->chrom < y->chrom ? -1 : 1;
	if (x->pos != y->pos) return x->pos < y->pos ? -1 : 1;
	return 0;
}

/*Orders the panel by rs number, for hps_find_id().*/
static int hps_cmp_id(const void *a, const void *b) {
	return strcmp(((const hps_site*)a)->id, ((const hps_site*)b)->id);
}

/*The marker at chrom and pos, or NULL.*/
static const hps_site *hps_find(const hps_reader *t, unsigned short int chrom, UV pos) {
	size_t lo = 0, hi = t->entries;
	while (lo < hi) {
		size_t mid = lo + (hi - lo) / 2;
		const hps_site *s = t->site + mid;
		if (s->chrom < chrom || (s->chrom == chrom && s->pos < pos)) lo = mid + 1;
		else if (s->chrom == chrom && s->pos == pos) return s;
		else hi = mid;
	}
	return NULL;
}

/*The marker whose rs number is the one name p..f, or NULL.*/
static const hps_site *hps_find_name(const hps_reader *t, const char *p, const char *f) {
	size_t n = (size_t)(f - p);
	if (n == 0 || n >= HPS_ID) return NULL;
	size_t lo = 0, hi = t->entries;
	while (lo < hi) {
		size_t mid = lo + (hi - lo) / 2;
		const hps_site *s = t->site + mid;
		int c = strncmp(s->id, p, n);
		if (c == 0 && s->id[n] != '\0') c = 1;// s->id runs on where p..f has ended, so it sorts after
		if (c < 0) lo = mid + 1;
		else if (c == 0) return s;
		else hi = mid;
	}
	return NULL;
}

/*The marker whose rs number is in the ID field p..f, or NULL. An ID of several
names, which the VCF specification separates with semicolons ("Semicolon-
separated list of unique identifiers where available", VCFv4.2 section 1.4.1,
field 3), is matched on the first of them that is a marker's. Up to 2026-11-10
only its first name was looked at, so that "foo;rs12913832" matched nothing.*/
static const hps_site *hps_find_id(const hps_reader *t, const char *p, const char *f) {
	for (;;) {
		const char *semi = (const char*)memchr(p, ';', (size_t)(f - p));
		const hps_site *s = hps_find_name(t, p, semi ? semi : f);
		if (s || !semi) return s;
		p = semi + 1;
	}
}

/*Whether the ALT a..ae is the REF r..re with the one base put in, in either
case. Past the bases the two share at the start, the first base of ALT that
differs is the one put in, and the rest of ALT must be the rest of REF; in a
run of that base it could have gone anywhere in the run, and gives the same
ALT. An MNV or a symbolic ALT such as <INS> fails it.*/
static bool hps_inserts(char base, const char *r, const char *re, const char *a, const char *ae) {
	const size_t rl = (size_t)(re - r);
	if ((size_t)(ae - a) != rl + 1) return FALSE;
	size_t i = 0;// the first place ALT differs from REF, read after the loop
	while (i < rl && toUPPER(r[i]) == toUPPER(a[i])) i++;
	if (toUPPER(a[i]) != toUPPER(base)) return FALSE;
	for (size_t j = i; j < rl; j++) {
		if (toUPPER(r[j]) != toUPPER(a[j + 1])) return FALSE;
	}
	return TRUE;
}

/*Where the marker's counted allele is among REF (0) and the ALTs (1, 2, ...),
or -1 when the record does not carry it at all, which leaves every call of the
record 0 copies of it. REF is ref..ref_end and ALT is alt..alt_end.*/
static short int hps_allele(const hps_site *s, const char *ref, const char *ref_end, const char *alt, const char *alt_end) {
	size_t ref_len = (size_t)(ref_end - ref);
	if (!s->insertion && ref_len == 1 && toUPPER(*ref) == toUPPER(s->allele)) return 0;
	short int i = 1;
	for (const char *q = alt; q <= alt_end; i++) {
		const char *c = (const char*)memchr(q, ',', (size_t)(alt_end - q));
		const char *ce = c ? c : alt_end;
		if (s->insertion ? hps_inserts(s->allele, ref, ref_end, q, ce) : (ce - q == 1 && toUPPER(*q) == toUPPER(s->allele))) return i;
		if (i == 127) break;// a short int holds no more, and no record of these markers has so many ALTs
		q = ce + 1;
	}
	return -1;
}

/*The sample field p..e at a marker whose counted allele is at idx, whose
FORMAT has GT at gt and DP at dp: how many of the two alleles are idx, or
HPS_NO_CALL for a genotype that is missing or partly missing, is not diploid,
or has a DP below min_depth. The panel is autosomal, so a haploid call is not
a dosage and is not counted as one.*/
static unsigned char hps_dose(const vcf_reader *r, const char *p, const char *e, size_t gt, size_t dp, short int idx) {
	const char *s, *sf;
	if (vcf_shallow(r, p, e, dp)) return HPS_NO_CALL;
	if (gt == VCF_ABSENT || !vcf_subfield(p, e, gt, &s, &sf) || s == sf) return HPS_NO_CALL;
	unsigned short int alleles = 0, carried = 0;
	while (s < sf) {
		if (*s < '0' || *s > '9') return HPS_NO_CALL;// missing ("."), or a separator where an allele belongs
		UV a = 0;
		for (; s < sf && *s >= '0' && *s <= '9'; s++) {
			if (a > (UV_MAX - 9) / 10) return HPS_NO_CALL;
			a = a * 10 + (UV)(*s - '0');
		}
		if (++alleles > 2) return HPS_NO_CALL;
		if (idx >= 0 && a == (UV)idx) carried++;
		if (s < sf) {
			if (*s != '/' && *s != '|') return HPS_NO_CALL;
			if (++s == sf) return HPS_NO_CALL;// a separator with no allele after it
		}
	}
	if (alleles != 2) return HPS_NO_CALL;
	return (unsigned char)carried;
}

static void hps_header(pTHX_ vcf_reader *r) {
	hps_reader *t = (hps_reader*)r;
	Newx(t->dose, r->n * t->sites, unsigned char);
	SAVEFREEPV(t->dose);// freed at the caller's LEAVE, croak or not; see vcf_read()'s block
	memset(t->dose, HPS_ABSENT, r->n * t->sites);
	Newxz(t->seen, t->sites, bool);
	SAVEFREEPV(t->seen);
	Newxz(t->carried, t->sites, bool);
	SAVEFREEPV(t->carried);
}

static void hps_record(pTHX_ vcf_reader *r, const char *p, const char *e) {
	hps_reader *t = (hps_reader*)r;
	const char *f = vcf_field_end(p, e);
	const hps_site *s;
	if (t->by_id) {
		if (f >= e) return;
		const char *pos = f + 1;
		const char *pos_end = vcf_field_end(pos, e);
		if (pos_end >= e) return;
		const char *id = pos_end + 1;
		s = hps_find_id(t, id, vcf_field_end(id, e));
	} else {
		unsigned short int chrom = vcf_chrom(p, f);
		if (chrom == 0 || chrom > 31 || !(t->chroms & ((uint32_t)1 << chrom))) return;
		if (f >= e) return;
		const char *pos = f + 1;
		s = hps_find(t, chrom, vcf_pos(aTHX_ r, pos, vcf_field_end(pos, e)));
	}
	if (!s) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	const char *ref = col[3], *ref_end = col[4] - 1;
	if (!s->insertion && ref_end - ref != 1) return;// some other variant sharing the marker's position
	short int idx = hps_allele(s, ref, ref_end, col[4], col[5] - 1);
	// A site split into one record per ALT reaches here once for each, and only
	// the record that carries the counted allele says anything about it; the
	// others would count every call 0. So a marker already counted from a record
	// that carried it is left alone, and one counted from a record that did not
	// is counted again when a later record does carry it.
	if (t->seen[s->k] && (t->carried[s->k] || idx < 0)) return;
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	t->seen[s->k] = TRUE;
	if (idx >= 0) t->carried[s->k] = TRUE;
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		t->dose[i * t->sites + s->k] = hps_dose(r, p, se, gt, dp, idx);
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
}

/*What perl gave to search for, as hps_site's. Each element of panel is
[chromosome, position, allele, insertion, rs number, marker], the chromosome
PLINK's number or 0 where no position is given, and marker the 0-based place
in the panel of markers that the entry's genotypes belong to. There is
normally one entry for each marker, and more than one where a marker is
searched for under an rs number that has since been merged into another, which
the file may use either of; markers says how many markers there are in all.*/
static void hps_panel(pTHX_ hps_reader *t, AV *panel, size_t markers) {
	t->entries = (size_t)(av_len(panel) + 1);
	t->sites = markers;
	if (!t->entries || !markers) croak("%s: the panel is empty", __func__);
	Newxz(t->site, t->entries, hps_site);
	SAVEFREEPV(t->site);
	for (SSize_t i = 0; i <= av_len(panel); i++) {
		SV **row = av_fetch(panel, i, 0);
		if (!row || !SvROK(*row) || SvTYPE(SvRV(*row)) != SVt_PVAV) croak("%s: entry %" IVdf " of the panel isn't an array ref", __func__, (IV)i);
		AV *m = (AV*)SvRV(*row);
		if (av_len(m) != 5) croak("%s: entry %" IVdf " of the panel has %" IVdf " fields, and needs 6", __func__, (IV)i, (IV)(av_len(m) + 1));
		SV **fld[6];
		for (unsigned short int k = 0; k < 6; k++) {
			fld[k] = av_fetch(m, (SSize_t)k, 0);
			if (!fld[k]) croak("%s: field %u of entry %" IVdf " of the panel is missing", __func__, (unsigned)k, (IV)i);
		}
		hps_site *s = t->site + i;
		s->k = (size_t)SvUV(*fld[5]);
		if (s->k >= markers) croak("%s: entry %" IVdf " of the panel is marker %" UVuf ", and there are %" UVuf, __func__, (IV)i, (UV)s->k, (UV)markers);
		s->chrom = (unsigned short int)SvUV(*fld[0]);
		s->pos = SvUV(*fld[1]);
		s->insertion = SvTRUE(*fld[3]) ? TRUE : FALSE;
		STRLEN len;
		const char *allele = SvPV(*fld[2], len);
		if (len != 1) croak("%s: entry %" IVdf " of the panel counts \"%.*s\", which isn't one base", __func__, (IV)i, (int)len, allele);
		s->allele = allele[0];
		const char *id = SvPV(*fld[4], len);
		if (!len || len >= HPS_ID) croak("%s: entry %" IVdf " of the panel is named \"%.*s\", which is %s", __func__, (IV)i, (int)len, id,
			len ? "longer than an rs number" : "empty");
		memcpy(s->id, id, len);
		s->id[len] = '\0';
		if (s->chrom && s->chrom < 32) t->chroms |= (uint32_t)1 << s->chrom;
	}
	qsort(t->site, t->entries, sizeof(hps_site), t->by_id ? hps_cmp_id : hps_cmp_pos);
}

/*The panel's genotypes for every sample of the VCF name, which next returns a
block of at a time. Returns sample => an array of one value for each marker of
the panel, in the panel's order: 0, 1 or 2 copies of the counted allele, or
undef where the sample had no call. *names is the samples in file order and
*seen one 0 or 1 for each marker, saying whether the file held a record of it
at all, which tells a marker nobody was called at from one nobody carries.*/
static HV *hps_dosage_vcf(pTHX_ SV *next, const char *name, UV min_depth, AV *panel, size_t markers, bool by_id, AV **names, AV **seen) {
	hps_reader t;
	Zero(&t, 1, hps_reader);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = hps_header;
	t.r.on_record = hps_record;
	t.by_id = by_id;
	hps_panel(aTHX_ &t, panel, markers);
	vcf_read(aTHX_ next, &t.r);
	HV *out = t.r.samples;
	for (size_t i = 0; i < t.r.n; i++) {
		SV **sample = av_fetch(t.r.names, (SSize_t)i, 0);
		if (!sample) croak("%s: sample %" UVuf " of %s has lost its name", __func__, (UV)i, name);// cannot happen: every sample read was pushed
		AV *row = newAV();
		av_extend(row, (SSize_t)t.sites - 1);
		for (size_t k = 0; k < t.sites; k++) {
			unsigned char d = t.dose[i * t.sites + k];
			av_push(row, d <= 2 ? newSVuv(d) : newSV(0));
		}
		(void)hv_store_ent(out, *sample, newRV_noinc((SV*)row), 0);// in place of the column vcf_header() stored
	}
	AV *was = newAV();
	av_extend(was, (SSize_t)t.sites - 1);
	for (size_t k = 0; k < t.sites; k++) av_push(was, newSVuv(t.seen[k] ? 1 : 0));
	*names = t.r.names;
	*seen = was;
	return out;
}

/*The genotypes behind blood_type().

Its markers are a panel like hirisplex_genotypes()'s -- three of ABO and the
sites of RHD at which somebody who has the gene almost always differs from
the reference -- so hps_record() reads them, and this adds the two things a
panel of markers cannot say.

One is a record of a deletion that covers the whole RHD gene, which is how
1000 Genomes' phase 3 writes the usual cause of RhD negative (1:25592642,
ALT <CN0>, END=25661222): its genotype is the answer, where the SNVs can only
say whether a sample has the gene at all. A deletion is an ALT of <CN0>,
<DEL> or <DEL:...>, the VCF specification's symbolic alleles, and how far it
runs is INFO's END, or else POS plus SVLEN (VCFv4.2, "INFO keys used for
structural variants").

The other is what the file could have shown. A VCF of one genome usually
lists only the sites where its sample carries an ALT allele, so perl takes a
marker with no record as homozygous REF; that is wrong for a file that could
not have held the record, so each chromosome a marker is on is noted when any
record of it is read, and again when a record of it has an allele longer than
one base, without which a file cannot have held ABO's insertion.

What is kept is hps_reader's byte a sample a marker and one more byte a
sample for the deletion.*/

typedef struct {
	hps_reader h;// first, so that the vcf_reader * bt_header() and bt_record() are given is this, and is what hps_record() takes
	unsigned short int chrom;// the gene's chromosome, in vcf_chrom()'s numbering
	UV start, end;// the gene, 1-based and inclusive, which a deletion has to cover
	uint32_t chroms;// bit c set for each chromosome c that a marker or the gene is on; a record of any other is read no further than CHROM
	uint32_t seen;// bit c set once a record of chromosome c has been read
	uint32_t longer;// bit c set once a record of chromosome c had a REF or an ALT longer than one base
	unsigned char *deleted;// one per sample: how many copies of a deletion covering the gene it has, 0 to 2, or HPS_ABSENT or HPS_NO_CALL
} bt_reader;

static void bt_header(pTHX_ vcf_reader *r) {
	bt_reader *t = (bt_reader*)r;
	hps_header(aTHX_ r);
	Newx(t->deleted, r->n, unsigned char);
	SAVEFREEPV(t->deleted);// freed at the caller's LEAVE, croak or not; see vcf_read()'s block
	memset(t->deleted, HPS_ABSENT, r->n);
}

/*Whether any allele of the ALT field p..e is longer than one base. A symbolic
allele ("<DEL>", "<NON_REF>") is a name, not bases, and is not one.*/
static bool bt_longer(const char *p, const char *e) {
	for (const char *q = p; q < e;) {
		const char *c = (const char*)memchr(q, ',', (size_t)(e - q));
		const char *ce = c ? c : e;
		if (ce - q > 1 && *q != '<') return TRUE;
		if (!c) break;
		q = ce + 1;
	}
	return FALSE;
}

/*Where a deletion is among the alleles of the ALT field p..e: 1 for the first
ALT, 2 for the second and so on, or -1 when none of them is one.*/
static short int bt_deletion(const char *p, const char *e) {
	short int i = 1;
	for (const char *q = p; q < e; i++) {
		const char *c = (const char*)memchr(q, ',', (size_t)(e - q));
		const char *ce = c ? c : e;
		const size_t n = (size_t)(ce - q);
		if ((n == 5 && (memcmp(q, "<CN0>", 5) == 0 || memcmp(q, "<DEL>", 5) == 0)) || (n > 5 && memcmp(q, "<DEL:", 5) == 0)) return i;
		if (!c || i == 127) break;// a short int holds no more, and no record has so many ALTs
		q = ce + 1;
	}
	return -1;
}

/*The whole number that key, which ends in its "=", has in the INFO field
p..e, in *v, or FALSE when INFO lacks the key or its value is not one. A "-"
before the number is passed over, since SVLEN is negative for a deletion, and
the number ends at a comma, since SVLEN has a value for each ALT.*/
static bool bt_info(const char *p, const char *e, const char *key, UV *v) {
	const size_t kl = strlen(key);
	for (const char *q = p; q < e;) {
		const char *semi = (const char*)memchr(q, ';', (size_t)(e - q));
		const char *qe = semi ? semi : e;
		if ((size_t)(qe - q) > kl && memcmp(q, key, kl) == 0) {
			const char *s = q + kl;
			if (s < qe && *s == '-') s++;
			if (s == qe || *s < '0' || *s > '9') return FALSE;
			UV n = 0;
			for (; s < qe && *s != ','; s++) {
				if (*s < '0' || *s > '9' || n > (UV_MAX - 9) / 10) return FALSE;
				n = n * 10 + (UV)(*s - '0');
			}
			*v = n;
			return TRUE;
		}
		if (!semi) break;
		q = qe + 1;
	}
	return FALSE;
}

static void bt_record(pTHX_ vcf_reader *r, const char *p, const char *e) {
	bt_reader *t = (bt_reader*)r;
	const char *f = vcf_field_end(p, e);
	const unsigned short int chrom = vcf_chrom(p, f);
	if (chrom == 0) return;
	const uint32_t bit = (uint32_t)1 << chrom;// chrom is 24 at most
	if (!(t->chroms & bit)) return;
	t->seen |= bit;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	const char *alt = col[4], *alt_end = col[5] - 1;
	if (col[4] - 1 - col[3] > 1 || bt_longer(alt, alt_end)) t->longer |= bit;
	if (t->h.chroms & bit) hps_record(aTHX_ r, p, e);
	if (chrom != t->chrom) return;
	const short int idx = bt_deletion(alt, alt_end);
	if (idx < 0) return;
	const UV pos = vcf_pos(aTHX_ r, col[1], col[2] - 1);
	const char *info = col[7], *info_end = col[8] - 1;
	UV end = 0, len = 0;
	if (!bt_info(info, info_end, "END=", &end) && bt_info(info, info_end, "SVLEN=", &len)) end = pos + len;
	if (pos > t->start || end < t->end) return;// some other deletion, which leaves part of the gene
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		// the first record that calls a sample is kept, should a file hold two
		if (t->deleted[i] > 2) t->deleted[i] = hps_dose(r, p, se, gt, dp, idx);
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
}

/*blood_type()'s panel for every sample of the VCF name, which next returns a
block of at a time. panel and markers are hps_panel()'s; chrom, start and end
are the gene a deletion has to cover. Returns, as hps_dosage_vcf() does,
sample => an array of one value for each marker, and sets *names and *seen as
it does. *deleted is one value for each sample, in file order: how many copies
of a deletion covering the gene it has, or undef where the file has no such
record or the sample no call of it. flags[0] has bit c set for each
chromosome c of the panel that the file has a record of, and flags[1] for each
that it has an allele longer than one base on.*/
static HV *bt_tally_vcf(pTHX_ SV *next, const char *name, UV min_depth, AV *panel, size_t markers, UV chrom, UV start, UV end, AV **names, AV **seen, AV **deleted, UV *flags) {
	if (chrom < 1 || chrom > 24 || start < 1 || start > end)
		croak("%s: the gene is chromosome %" UVuf ", %" UVuf " to %" UVuf ", which isn't a stretch of a chromosome", __func__, chrom, start, end);
	bt_reader t;
	Zero(&t, 1, bt_reader);
	t.h.r.name = name;
	t.h.r.min_depth = min_depth;
	t.h.r.on_header = bt_header;
	t.h.r.on_record = bt_record;
	t.chrom = (unsigned short int)chrom;
	t.start = start;
	t.end = end;
	hps_panel(aTHX_ &t.h, panel, markers);
	t.chroms = t.h.chroms | ((uint32_t)1 << t.chrom);
	vcf_read(aTHX_ next, &t.h.r);
	HV *out = t.h.r.samples;
	AV *lost = newAV();
	av_extend(lost, (SSize_t)t.h.r.n - 1);
	for (size_t i = 0; i < t.h.r.n; i++) {
		SV **sample = av_fetch(t.h.r.names, (SSize_t)i, 0);
		if (!sample) croak("%s: sample %" UVuf " of %s has lost its name", __func__, (UV)i, name);// cannot happen: every sample read was pushed
		AV *row = newAV();
		av_extend(row, (SSize_t)t.h.sites - 1);
		for (size_t k = 0; k < t.h.sites; k++) {
			const unsigned char d = t.h.dose[i * t.h.sites + k];
			av_push(row, d <= 2 ? newSVuv(d) : newSV(0));
		}
		(void)hv_store_ent(out, *sample, newRV_noinc((SV*)row), 0);// in place of the column vcf_header() stored
		av_push(lost, t.deleted[i] <= 2 ? newSVuv(t.deleted[i]) : newSV(0));
	}
	AV *was = newAV();
	av_extend(was, (SSize_t)t.h.sites - 1);
	for (size_t k = 0; k < t.h.sites; k++) av_push(was, newSVuv(t.h.seen[k] ? 1 : 0));
	*names = t.h.r.names;
	*seen = was;
	*deleted = lost;
	flags[0] = (UV)t.seen;
	flags[1] = (UV)t.longer;
	return out;
}

/*---- translation and k-mers: translate(), translate_six_frames(), find_orfs()
and kmer_count().

A genetic code arrives as the 64 letters of one line of
share/genetic_codes.tsv, which is NCBI's ncbieaa: the amino acid of each codon
in the order TTT, TTC, TTA, TTG, TCT .. GGG, with '*' for a stop. The rules for
a codon with an ambiguous base are Biopython 1.87's (Bio/Seq.py,
_translate_str(), and AmbiguousForwardTable in Bio/Data/CodonTable.py), which
t/seq.t checks against that library's own tests.*/

/*The bases that the IUPAC nucleotide letter c stands for, as a set of bits in
the codes' own base order: 1 = T or U, 2 = C, 4 = A, 8 = G; 0 when c is not a
nucleotide letter. The letters are those of NC-IUB's "Nomenclature for
incompletely specified bases in nucleic acid sequences" (1984), as Biopython
1.87 lists them in ambiguous_dna_values of Bio/Data/IUPACData.py. That table
also has X, kept there "for historical reasons although it is not an IUPAC
nucleotide"; it is left out here, so a codon with an X is refused.*/
static unsigned char nt_set(char c) {
	switch (c) {
		case 'T': case 't': case 'U': case 'u': return 1;
		case 'C': case 'c': return 2;
		case 'A': case 'a': return 4;
		case 'G': case 'g': return 8;
		case 'Y': case 'y': return 1 | 2;// C or T
		case 'W': case 'w': return 1 | 4;// A or T
		case 'K': case 'k': return 1 | 8;// G or T
		case 'M': case 'm': return 2 | 4;// A or C
		case 'S': case 's': return 2 | 8;// C or G
		case 'R': case 'r': return 4 | 8;// A or G
		case 'H': case 'h': return 1 | 2 | 4;// not G
		case 'B': case 'b': return 1 | 2 | 8;// not A
		case 'D': case 'd': return 1 | 4 | 8;// not C
		case 'V': case 'v': return 2 | 4 | 8;// not T
		case 'N': case 'n': return 1 | 2 | 4 | 8;
		default: return 0;
	}
}

/*Whether the base set s holds exactly one base.*/
#define NT_ONE(s) (((s) & ((s) - 1)) == 0)
/*The place in T, C, A, G order of the one base in the set s: 1, 2, 4, 8 give
0, 1, 2, 3.*/
#define NT_INDEX(s) (((s) >> 1) - ((s) >> 3))
/*The bit that stands for the letter c of a code in codon_letter()'s set: one
for each letter from 'A' on, and bit 63 for a stop. A 64-bit set rather than a
32-bit one, so that it also holds on EBCDIC, where 'Z' - 'A' is 40.*/
#define AA_BIT(c) (UINT64_C(1) << ((c) == '*' ? 63 : (c) - 'A'))

/*The letter that a codon is translated to under code, where s1, s2 and s3 are
nt_set() of its three letters, none of them 0: '*' for a stop.

A codon of three plain bases is looked up. One with an ambiguous base stands
for several codons, and is given what they agree on: their amino acid when they
have one between them, '*' when every one is a stop, B for D and N together, Z
for E and Q, J for I and L, and X for anything else, a mix of stops and amino
acids included. Those are Biopython's rules: B, Z and J are the only letters of
its extended_protein_values that stand for two amino acids, and X is its
pos_stop.*/
static char codon_letter(const char *code, unsigned char s1, unsigned char s2, unsigned char s3) {
	if (NT_ONE(s1) && NT_ONE(s2) && NT_ONE(s3)) return code[16 * NT_INDEX(s1) + 4 * NT_INDEX(s2) + NT_INDEX(s3)];
	uint64_t seen = 0;// AA_BIT() of every letter the codon could be
	char last = 'X';// one of those letters, which is the answer when there is only one
	for (unsigned short int i = 0; i < 4; i++) {
		if (!(s1 >> i & 1)) continue;
		for (unsigned short int j = 0; j < 4; j++) {
			if (!(s2 >> j & 1)) continue;
			for (unsigned short int k = 0; k < 4; k++) {
				if (!(s3 >> k & 1)) continue;
				last = code[16 * i + 4 * j + k];
				seen |= AA_BIT(last);
			}
		}
	}
	if (NT_ONE(seen)) return last;
	if (seen == (AA_BIT('D') | AA_BIT('N'))) return 'B';
	if (seen == (AA_BIT('E') | AA_BIT('Q'))) return 'Z';
	if (seen == (AA_BIT('I') | AA_BIT('L'))) return 'J';
	return 'X';
}

/*seq translated under code, as a new mortal SV: one letter for each three of
seq's, a stop written as stop_symbol, and whatever is left after the last whole
codon dropped. With to_stop, the translation ends before the first stop. With
gap other than NULL, a codon of three *gap is written as *gap.

A codon with any other letter that is not a nucleotide's dies, and names the
codon. The SV is mortal so that dying then does not leak it.*/
static SV *translate_codons(pTHX_ SV *seq, SV *code_sv, char stop_symbol, bool to_stop, const char *gap) {
	STRLEN code_len, len;
	const char *code = SvPV_const(code_sv, code_len);// not restrict: perl's buffer
	if (code_len != 64) croak("%s: a genetic code is 64 letters, not %" UVuf, __func__, (UV)code_len);
	for (unsigned short int i = 0; i < 64; i++) {
		if (code[i] != '*' && !isUPPER(code[i])) croak("%s: letter %" UVuf " of the genetic code \"%s\" is neither a capital letter nor *", __func__, (UV)i + 1, code);
	}
	const char *p = SvPV_const(seq, len);// not restrict: perl's buffer
	const size_t codons = len / 3;
	SV *out = sv_2mortal(newSV(codons ? codons : 1));
	SvPOK_only(out);
	char *o = SvPVX(out);
	size_t n = 0;// letters written, which is read after the loop
	for (size_t i = 0; i < codons; i++) {
		const char *c = p + 3 * i;
		const unsigned char s1 = nt_set(c[0]), s2 = nt_set(c[1]), s3 = nt_set(c[2]);
		if (!s1 || !s2 || !s3) {
			if (gap && c[0] == *gap && c[1] == *gap && c[2] == *gap) {
				o[n++] = *gap;
				continue;
			}
			croak("%s: codon %" UVuf ", \"%.3s\", has a letter that isn't a nucleotide's", __func__, (UV)(i + 1), c);
		}
		const char aa = codon_letter(code, s1, s2, s3);
		if (aa != '*') {
			o[n++] = aa;
		} else if (to_stop) {
			break;
		} else {
			o[n++] = stop_symbol;
		}
	}
	o[n] = '\0';
	SvCUR_set(out, n);
	return out;
}

/*How many times each run of k bytes occurs in seq, as a new hash of run =>
count: the run at every step-th byte, so step 1 counts every k-mer and step k
those that do not overlap. A k of 0 or longer than seq gives an empty hash.

The runs are bytes, so lib/Cn/Bioinf.pm counts a string that holds a character
above 255 itself. A hash key's length is an I32, and a negative one means a
UTF-8 key, so a k beyond I32_MAX dies; perl refuses it first.*/
static HV *kmer_tally(pTHX_ SV *seq, UV k, UV step) {
	STRLEN len;
	const char *p = SvPV_const(seq, len);// not restrict: perl's buffer
	HV *h = (HV*)sv_2mortal((SV*)newHV());
	if (k > (UV)I32_MAX) croak("%s: k is %" UVuf ", and a hash key can be no longer than %" IVdf, __func__, k, (IV)I32_MAX);
	if (step == 0) croak("%s: a step of 0 would count the first k-mer for ever", __func__);// cannot happen: perl passes 1 or k
	if (k == 0 || k > len) return h;
	const size_t last = len - (size_t)k;// where the last k-mer starts
	for (size_t i = 0; i <= last; i += (size_t)step) {
		SV **count = hv_fetch(h, p + i, (I32)k, 1);
		if (!count) croak("%s: couldn't count the k-mer at %" UVuf, __func__, (UV)i);// cannot happen: an lvalue fetch from a plain hash
		sv_setuv(*count, SvOK(*count) ? SvUV(*count) + 1 : 1);
		if (step > last - i) break;// i + step would pass the end, and could wrap
	}
	return h;
}

/*Width-correct libm for NV, behind admixture()'s fit.

This is the macro scheme of ~/Scripts/stats/LikeR.xs, cut down to the two
functions the fit calls, log() and sqrt(), where LikeR.xs defines thirty:
copying the rest would only be unused code. C's log() and sqrt() take a double,
so on a long-double or __float128 perl an NV would be computed at a double's
precision; the macros paste on the suffix for the width NV is. Makefile.PL
link-tests logl() and sqrtl() on a long-double perl and defines
BIOINF_HAVE_LONG_DOUBLE_MATH when both resolve, and the double functions are
used otherwise. A quadmath perl's $Config{perllibs} already carries
-lquadmath, and perl.h has already included <quadmath.h>.*/
#if defined(USE_QUADMATH)
#  define BIOINF_NVFN(base) base ## q
#elif defined(USE_LONG_DOUBLE) && defined(BIOINF_HAVE_LONG_DOUBLE_MATH)
#  define BIOINF_NVFN(base) base ## l
#else
#  define BIOINF_NVFN(base) base
#endif
#define nv_log(x)  BIOINF_NVFN(log)(x)
#define nv_sqrt(x) BIOINF_NVFN(sqrt)(x)

/*Admixture proportions, for admixture() (since 2026-11-17).

The model is ADMIXTURE's (Alexander, Novembre and Lange 2009, "Fast
model-based estimation of ancestry in unrelated individuals", Genome Research
19:1655-1664): sample i descends from K ancestral populations in the
fractions q[i][0..K-1], which sum to 1, and population l carries variant j's
ALT allele at the frequency p[j][l]. Sample i's ALT count g at variant j is
then binomial, of 2 draws with probability f = sum over l of q[i][l] p[j][l],
and the log-likelihood is the sum over the called genotypes of
g log f + (2 - g) log(1 - f), which leaves out the binomial coefficient, as
ADMIXTURE's printed log-likelihood does.

It is maximized by the EM algorithm of Tang, Peng, Wang and Risch (2005,
"Estimation of individual admixture: analytical and study design
considerations", Genetic Epidemiology 28:289-301, the method of their program
frappe): with a = g q[i][l] p[j][l] / f and b = (2 - g) q[i][l] (1 - p[j][l]) /
(1 - f), the new p[j][l] is the sum over i of a divided by the sum of a + b, and
the new q[i][l] the sum over j of a + b divided by twice sample i's called
genotypes. The steps are accelerated by SQUAREM (Varadhan and Roland 2008,
"Simple and globally convergent methods for accelerating the convergence of any
EM algorithm", Scandinavian Journal of Statistics 35:335-353), their scheme S3
with the steplength held at -1 or below, a stabilizing EM step after each
extrapolation, and the second plain EM step kept instead whenever the
extrapolation lowers the likelihood, so that no iteration does. ADMIXTURE
itself climbs the same likelihood by block relaxation and quasi-Newton
acceleration. The likelihood has local maxima, so lib/Cn/Bioinf.pm fits from
several random starts and keeps the best.*/
#define ADMIX_MISSING 3 // a genotype byte with no call; 0 to 2 are its ALT count
/*The least q and p, and 1 less it the most: ADMIXTURE 1.3.0's bounds, which
its .Q files show as 0.000010 for a fraction it drove to the bound. A
frequency of exactly 0 or 1 would make log(0) of a genotype that disagrees.*/
#define ADMIX_BOUND ((NV)1e-5)

typedef struct {
	vcf_reader r;// first, so that the vcf_reader * that the callbacks are given is this
	SV *g;// the genotype bytes, r.n to a variant, in the VCF's order
	AV *variants;// each variant kept, as "CHROM\tPOS\tID\tREF\tALT"
	UV *called;// each sample's called genotypes
} admix_reader;

static void admix_header(pTHX_ vcf_reader *r) {
	admix_reader *t = (admix_reader*)r;
	Newxz(t->called, r->n, UV);
	SAVEFREEPV(t->called);// at the caller's LEAVE, croak or not; see vcf_read()'s block
}

/*The record p..e, kept when it is on an autosome and biallelic: one ALT,
which is not "." (no ALT) or "*" (a deletion's overlap), as PLINK 2's
--max-alleles 2 --min-alleles 2 keeps them, which is what made t/admixture.t's
reference input. A call of one allele, or of none, is missing.*/
static void admix_record(pTHX_ vcf_reader *r, const char *p, const char *e) {
	admix_reader *t = (admix_reader*)r;
	const char *f = vcf_field_end(p, e);
	const unsigned short int chrom = vcf_chrom(p, f);
	if (chrom == 0 || chrom > 22) return;
	const char *col[9];
	const char *format_end = vcf_columns(aTHX_ r, p, f, e, col);
	const char *alt = col[4], *alt_end = col[5] - 1;
	if (alt == alt_end || memchr(alt, ',', (size_t)(alt_end - alt)) || (alt_end - alt == 1 && (*alt == '.' || *alt == '*'))) return;
	size_t gt, dp;
	vcf_format(col[8], format_end, &gt, &dp);
	if (gt == VCF_ABSENT) return;
	const STRLEN at = SvCUR(t->g);
	if ((STRLEN)r->n > ((STRLEN)-1 - at) / 2 - 1) croak("%s: %s has too many genotypes to hold, at line %" UVuf, __func__, r->name, r->line);
	// doubled when full, so that the bytes are copied O(log variants) times, not once a record
	if (SvLEN(t->g) < at + r->n + 1) SvGROW(t->g, 2 * (at + r->n) + 1);
	unsigned char *row = (unsigned char*)SvPVX(t->g) + at;// not restrict: perl's buffer
	p = format_end + 1;
	for (size_t i = 0; i < r->n; i++) {
		const char *se = vcf_sample(aTHX_ r, p, e, i);
		unsigned short int alleles = 0, alts = 0;
		const bool call = vcf_call(r, p, se, gt, dp, &alleles, &alts) == VCF_CALL && alleles == 2;
		row[i] = call ? (unsigned char)alts : ADMIX_MISSING;
		if (call) t->called[i]++;
		p = se + 1;
	}
	vcf_samples_end(aTHX_ r, p, e);
	SvCUR_set(t->g, at + r->n);
	av_push(t->variants, newSVpvf("%.*s\t%.*s\t%.*s\t%.*s\t%.*s", (int)(col[1] - 1 - col[0]), col[0], (int)(col[2] - 1 - col[1]), col[1],
		(int)(col[3] - 1 - col[2]), col[2], (int)(col[4] - 1 - col[3]), col[3], (int)(alt_end - alt), alt));
}

typedef struct {
	const unsigned char *g;// m rows of n genotype bytes; perl's buffer, not written
	size_t n, m, k;// samples, variants, ancestral populations
	NV *twice;// each sample's called genotypes, twice: the alleles its q is a share of
	NV *num, *den;// k each, admix_em()'s sums for one variant
} admix_fit;

/*The parameters, q (n rows of k) and then p (m rows of k), held to the
bounds: each q row clamped and made to sum to 1 again, each p clamped.*/
static void admix_bound(const admix_fit *a, NV *th) {
	const size_t k = a->k;
	for (size_t i = 0; i < a->n; i++) {
		NV *q = th + i * k;
		NV sum = 0;
		for (size_t l = 0; l < k; l++) {
			if (!(q[l] >= ADMIX_BOUND)) q[l] = ADMIX_BOUND;// also NaN, which an extrapolation can make
			else if (q[l] > 1 - ADMIX_BOUND) q[l] = 1 - ADMIX_BOUND;
			sum += q[l];
		}
		for (size_t l = 0; l < k; l++) q[l] /= sum;
	}
	NV *p = th + a->n * k;
	for (size_t x = 0; x < a->m * k; x++) {
		if (!(p[x] >= ADMIX_BOUND)) p[x] = ADMIX_BOUND;
		else if (p[x] > 1 - ADMIX_BOUND) p[x] = 1 - ADMIX_BOUND;
	}
}

static NV admix_loglik(const admix_fit *a, const NV *th) {
	const size_t n = a->n, k = a->k;
	const NV *q = th, *p = th + n * k;
	NV ll = 0;
	for (size_t j = 0; j < a->m; j++) {
		const unsigned char *row = a->g + j * n;
		const NV *pj = p + j * k;
		for (size_t i = 0; i < n; i++) {
			const unsigned char c = row[i];
			if (c == ADMIX_MISSING) continue;
			const NV *qi = q + i * k;
			NV f = 0;
			for (size_t l = 0; l < k; l++) f += qi[l] * pj[l];
			if (c) ll += (NV)c * nv_log(f);
			if (c < 2) ll += (NV)(2 - c) * nv_log(1 - f);
		}
	}
	return ll;
}

/*One EM step from th into out, both laid out as admix_bound() describes.*/
static void admix_em(const admix_fit *a, const NV *th, NV *out) {
	const size_t n = a->n, k = a->k;
	const NV *q = th, *p = th + n * k;
	NV *q2 = out, *p2 = out + n * k;
	Zero(q2, n * k, NV);
	for (size_t j = 0; j < a->m; j++) {
		const unsigned char *row = a->g + j * n;
		const NV *pj = p + j * k;
		Zero(a->num, k, NV);
		Zero(a->den, k, NV);
		for (size_t i = 0; i < n; i++) {
			const unsigned char c = row[i];
			if (c == ADMIX_MISSING) continue;
			const NV *qi = q + i * k;
			NV f = 0;
			for (size_t l = 0; l < k; l++) f += qi[l] * pj[l];
			const NV x = c ? (NV)c / f : 0, y = c < 2 ? (NV)(2 - c) / (1 - f) : 0;
			NV *q2i = q2 + i * k;
			for (size_t l = 0; l < k; l++) {
				const NV alt = x * qi[l] * pj[l], ref = y * qi[l] * (1 - pj[l]);
				q2i[l] += alt + ref;
				a->num[l] += alt;
				a->den[l] += alt + ref;
			}
		}
		for (size_t l = 0; l < k; l++) p2[j * k + l] = a->den[l] > 0 ? a->num[l] / a->den[l] : pj[l];
	}
	for (size_t i = 0; i < n; i++) {
		NV *q2i = q2 + i * k;
		// a sample with no called genotype says nothing of its ancestry, and keeps an even share
		for (size_t l = 0; l < k; l++) q2i[l] = a->twice[i] > 0 ? q2i[l] / a->twice[i] : (NV)1 / (NV)k;
	}
	admix_bound(a, out);
}

/*The next of the 64-bit numbers that *s seeds, by SplitMix64 (Steele, Lea
and Flood 2014; the constants of Sebastiano Vigna's public-domain
splitmix64.c, prng.di.unimi.it), which gives the same numbers on every
platform, where rand() and perl's own do not.*/
static uint64_t admix_rand(uint64_t *s) {
	uint64_t z = (*s += UINT64_C(0x9E3779B97F4A7C15));
	z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
	z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
	return z ^ (z >> 31);
}

/*A random start from seed: each q row uniform numbers made to sum to 1, and
each p uniform, then held to the bounds. The top 53 bits of each number are
used, which a double holds exactly, so that the start is the same on a
long-double perl.*/
static void admix_start(const admix_fit *a, NV *th, uint64_t seed) {
	const NV unit = (NV)1 / (NV)UINT64_C(9007199254740992);// 2^-53
	for (size_t x = 0; x < (a->n + a->m) * a->k; x++) th[x] = (NV)(admix_rand(&seed) >> 11) * unit;
	admix_bound(a, th);
}

/*Fits from the start in th, leaving the fit there; returns its
log-likelihood, with the iterations in *iterations, and whether it converged
(the log-likelihood rose by less than tol in the last) in *converged. Each
iteration is a SQUAREM cycle of three EM steps.*/
static NV admix_run(pTHX_ const admix_fit *a, NV *th, UV max_iterations, NV tol, UV *iterations, bool *converged) {
	const size_t len = (a->n + a->m) * a->k;
	NV *t1, *t2, *t3;
	Newx(t1, len, NV);
	SAVEFREEPV(t1);
	Newx(t2, len, NV);
	SAVEFREEPV(t2);
	Newx(t3, len, NV);
	SAVEFREEPV(t3);
	NV ll = admix_loglik(a, th);
	*converged = FALSE;
	*iterations = 0;
	while (*iterations < max_iterations) {
		++*iterations;
		admix_em(a, th, t1);
		admix_em(a, t1, t2);
		NV sr = 0, sv = 0;
		for (size_t x = 0; x < len; x++) {
			const NV r = t1[x] - th[x], v = t2[x] - 2 * t1[x] + th[x];
			sr += r * r;
			sv += v * v;
		}
		NV next;
		const NV *keep = t2;// the parameters this iteration ends at
		if (sv > 0) {
			NV alpha = -nv_sqrt(sr / sv);
			if (alpha > -1) alpha = -1;
			for (size_t x = 0; x < len; x++) t3[x] = th[x] - 2 * alpha * (t1[x] - th[x]) + alpha * alpha * (t2[x] - 2 * t1[x] + th[x]);
			admix_bound(a, t3);
			admix_em(a, t3, t1);// t1 is not needed again
			next = admix_loglik(a, t1);
			if (next >= ll) keep = t1;// not NaN, and no lower
			else next = admix_loglik(a, t2);
		} else {
			next = admix_loglik(a, t2);
		}
		Copy(keep, th, len, NV);
		const NV rise = next - ll;
		ll = next;
		if (rise < tol) {
			*converged = TRUE;
			break;
		}
	}
	return ll;
}

MODULE = Cn::Bioinf	PACKAGE = Cn::Bioinf
PROTOTYPES: DISABLE

SV *
_read_fasta(fh, key, name, order = NULL)
	PerlIO *fh
	SV *key
	const char *name
	AV *order
CODE:
	RETVAL = read_fasta(aTHX_ fh, SvOK(key) ? key : NULL, name, order);
OUTPUT:
	RETVAL

void
_write_fasta(fh, h, order, width)
	PerlIO *fh
	HV *h
	AV *order
	UV width
CODE:
	write_fasta(aTHX_ fh, h, order, (STRLEN)width);

void
_fai_build(fh)
	PerlIO *fh
PPCODE:
	fai_state s;
	Zero(&s, 1, fai_state);
	s.text = sv_2mortal(newSVpvs(""));
	s.seen = (HV*)sv_2mortal((SV*)newHV());
	s.dups = (AV*)sv_2mortal((SV*)newAV());
	s.def = sv_2mortal(newSVpvs(""));
	s.name = sv_2mortal(newSVpvs(""));
	char *restrict buf;
	Newx(buf, FASTA_BLOCK, char);
	SAVEFREEPV(buf);// freed at this call's LEAVE, croak or not
	fai_scan(aTHX_ fh, &s, buf);
	EXTEND(SP, 6);
	PUSHs(s.text);
	PUSHs(sv_2mortal(newRV_inc((SV*)s.dups)));
	PUSHs(s.error ? sv_2mortal(newSVpv(s.error, 0)) : &PL_sv_undef);
	PUSHs(sv_2mortal(fai_number(aTHX_ s.line)));
	PUSHs(s.named ? s.name : &PL_sv_undef);
	PUSHs(s.error && strEQ(s.error, "read") ? sv_2mortal(newSVpv(Strerror(s.read_errno), 0)) : &PL_sv_undef);

void
_sex_tally(next, name, min_depth)
	SV *next
	const char *name
	UV min_depth
PPCODE:
	UV x_sites;
	AV *names;
	PUTBACK;
	HV *out = sex_tally_vcf(aTHX_ next, name, min_depth, &x_sites, &names);
	SPAGAIN;
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newRV_inc((SV*)out)));
	PUSHs(sv_2mortal(newSVuv(x_sites)));
	PUSHs(sv_2mortal(newRV_inc((SV*)names)));

void
_parent_one(next, name, min_depth, child, parent)
	SV *next
	const char *name
	UV min_depth
	SV *child
	SV *parent
PPCODE:
	parent_reader t;
	Zero(&t, 1, parent_reader);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = parent_header_one;
	t.r.on_record = parent_record_one;
	t.want[0] = child;
	t.want[1] = parent;
	PUTBACK;
	vcf_read(aTHX_ next, &t.r);
	SPAGAIN;
	UV in = 0;// the sites where either carries the ALT, every one of them in both, since there is one file
	for (unsigned short int k = 1; k < 9; k++) in += t.t[k];
	EXTEND(SP, 12);
	for (unsigned short int k = 0; k < 9; k++) PUSHs(sv_2mortal(newSVuv(t.t[k])));
	PUSHs(sv_2mortal(newSVuv(in)));
	PUSHs(sv_2mortal(newSVuv(0)));
	PUSHs(sv_2mortal(newSVuv(0)));

void
_parent_own(child_next, child_name, parent_next, parent_name, min_depth)
	SV *child_next
	const char *child_name
	SV *parent_next
	const char *parent_name
	UV min_depth
PPCODE:
	PUTBACK;
	const parent_sites *a = parent_sites_vcf(aTHX_ child_next, child_name, min_depth);
	const parent_sites *b = parent_sites_vcf(aTHX_ parent_next, parent_name, min_depth);
	SPAGAIN;
	UV t[9] = { 0 }, in[3] = { 0 };// as parent_merge() fills them
	parent_merge(a, b, t, in);
	EXTEND(SP, 12);
	for (unsigned short int k = 0; k < 9; k++) PUSHs(sv_2mortal(newSVuv(t[k])));
	for (unsigned short int k = 0; k < 3; k++) PUSHs(sv_2mortal(newSVuv(in[k])));

void
_relatedness_one(next, name, min_depth)
	SV *next
	const char *name
	UV min_depth
PPCODE:
	rel_reader t;
	Zero(&t, 1, rel_reader);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = rel_header_one;
	t.r.on_record = rel_record_one;
	PUTBACK;
	vcf_read(aTHX_ next, &t.r);
	if (t.k) rel_flush(&t);
	SPAGAIN;
	HV *sex = (HV*)sv_2mortal((SV*)newHV());
	sex_rows(aTHX_ sex, t.r.names, t.sex, t.r.n, name);
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newRV_inc((SV*)t.r.names)));
	PUSHs(sv_2mortal(rel_counts(aTHX_ t.t, t.r.n)));
	PUSHs(sv_2mortal(newRV_inc((SV*)sex)));

void
_relatedness_own(nexts, files, min_depth)
	AV *nexts
	AV *files
	UV min_depth
PPCODE:
	const size_t n = (size_t)(av_len(nexts) + 1);
	if ((SSize_t)n != av_len(files) + 1) croak("_relatedness_own: %" UVuf " readers for %" UVuf " files", (UV)n, (UV)(av_len(files) + 1));// cannot happen: perl makes one for each; named literally, since __func__ in an XSUB is XS_Cn__Bioinf__relatedness_own
	parent_sites **s;// each file's sites, freed by parent_sites_read()'s destructor
	Newx(s, n, parent_sites*);
	SAVEFREEPV(s);
	UV *count;// SEX_FIELDS counters a file
	Newxz(count, n * SEX_FIELDS, UV);
	SAVEFREEPV(count);
	HV *seen = (HV*)sv_2mortal((SV*)newHV());
	AV *names = (AV*)sv_2mortal((SV*)newAV());
	PUTBACK;
	for (size_t f = 0; f < n; f++) {
		SV **next = av_fetch(nexts, (SSize_t)f, 0), **file = av_fetch(files, (SSize_t)f, 0);
		if (!next || !file) croak("_relatedness_own: file %" UVuf " has no reader", (UV)f);// cannot happen: perl fills both arrays
		rel_own_reader t;
		Zero(&t, 1, rel_own_reader);
		t.p.r.name = SvPV_nolen(*file);
		t.p.r.min_depth = min_depth;
		t.p.r.on_header = rel_header_own;
		t.p.r.on_record = rel_record_own;
		t.sex = count + f * SEX_FIELDS;
		t.seen = seen;
		t.names = names;
		s[f] = parent_sites_read(aTHX_ &t.p, *next);
	}
	SPAGAIN;
	UV *t;// REL_T counters a pair
	Newxz(t, rel_pairs(aTHX_ n) * REL_T, UV);
	SAVEFREEPV(t);
	rel_merge(aTHX_ (parent_sites *const *)s, n, t);
	HV *sex = (HV*)sv_2mortal((SV*)newHV());
	sex_rows(aTHX_ sex, names, count, n, "the VCFs");
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newRV_inc((SV*)names)));
	PUSHs(sv_2mortal(rel_counts(aTHX_ t, n)));
	PUSHs(sv_2mortal(newRV_inc((SV*)sex)));

void
_vcf_samples(next, name)
	SV *next
	const char *name
PPCODE:
	vcf_reader r;
	Zero(&r, 1, vcf_reader);
	r.name = name;
	r.on_header = conc_stop;
	r.on_record = conc_skip;
	PUTBACK;
	vcf_read(aTHX_ next, &r);
	SPAGAIN;
	XPUSHs(sv_2mortal(newRV_inc((SV*)r.names)));

void
_concordance(test_next, test_name, truth_next, truth_name, truth_names, min_depth, discordances)
	SV *test_next
	const char *test_name
	SV *truth_next
	const char *truth_name
	AV *truth_names
	UV min_depth
	bool discordances
PPCODE:
	conc_store *s;
	Newxz(s, 1, conc_store);
	SAVEDESTRUCTOR_X(conc_store_free, s);// at this call's LEAVE, croak or not
	s->truth_n = (size_t)(av_len(truth_names) + 1);
	conc_reader test;
	Zero(&test, 1, conc_reader);
	test.r.name = test_name;
	test.r.min_depth = min_depth;
	test.r.on_header = conc_header_test;
	test.r.on_record = conc_record_test;
	test.s = s;
	test.truth_names = truth_names;
	PUTBACK;
	vcf_read(aTHX_ test_next, &test.r);
	conc_reader truth;
	Zero(&truth, 1, conc_reader);
	truth.r.name = truth_name;
	truth.r.min_depth = min_depth;
	truth.r.on_header = conc_header_truth;
	truth.r.on_record = conc_record_truth;
	truth.s = s;
	vcf_read(aTHX_ truth_next, &truth.r);
	SPAGAIN;
	HV *out = conc_results(aTHX_ s, test.r.names, truth.r.names, discordances);
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newRV_inc((SV*)out)));
	PUSHs(sv_2mortal(newRV_inc((SV*)test.r.names)));

void
_hirisplex_dosage(next, name, min_depth, panel, markers, by_id)
	SV *next
	const char *name
	UV min_depth
	AV *panel
	UV markers
	UV by_id
PPCODE:
	AV *names, *seen;
	PUTBACK;
	HV *out = hps_dosage_vcf(aTHX_ next, name, min_depth, panel, (size_t)markers, by_id ? TRUE : FALSE, &names, &seen);
	SPAGAIN;
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newRV_inc((SV*)out)));
	PUSHs(sv_2mortal(newRV_inc((SV*)names)));
	PUSHs(sv_2mortal(newRV_noinc((SV*)seen)));

void
_blood_type_tally(next, name, min_depth, panel, markers, chrom, start, end)
	SV *next
	const char *name
	UV min_depth
	AV *panel
	UV markers
	UV chrom
	UV start
	UV end
PPCODE:
	AV *names, *seen, *deleted;
	UV flags[2];// bt_tally_vcf()'s: the chromosomes read, and those with an allele longer than a base
	PUTBACK;
	HV *out = bt_tally_vcf(aTHX_ next, name, min_depth, panel, (size_t)markers, chrom, start, end, &names, &seen, &deleted, flags);
	SPAGAIN;
	EXTEND(SP, 6);
	PUSHs(sv_2mortal(newRV_inc((SV*)out)));
	PUSHs(sv_2mortal(newRV_inc((SV*)names)));
	PUSHs(sv_2mortal(newRV_noinc((SV*)seen)));
	PUSHs(sv_2mortal(newRV_noinc((SV*)deleted)));
	PUSHs(sv_2mortal(newSVuv(flags[0])));
	PUSHs(sv_2mortal(newSVuv(flags[1])));

SV *
_translate(seq, code, stop_symbol, to_stop, gap)
	SV *seq
	SV *code
	char stop_symbol
	UV to_stop
	SV *gap
CODE:
	// On a line of its own: SvREFCNT_inc_simple_NN() is a macro that evaluates
	// its argument twice, and would translate twice. The mortal is kept by
	// taking a second reference to it.
	SV *protein = translate_codons(aTHX_ seq, code, stop_symbol, to_stop ? TRUE : FALSE, SvOK(gap) ? SvPV_nolen(gap) : NULL);
	RETVAL = SvREFCNT_inc_simple_NN(protein);
OUTPUT:
	RETVAL

SV *
_kmer_count(seq, k, step)
	SV *seq
	UV k
	UV step
CODE:
	RETVAL = newRV_inc((SV*)kmer_tally(aTHX_ seq, k, step));// inc, since the hash is mortal
OUTPUT:
	RETVAL

void
_admixture_genotypes(next, name, min_depth)
	SV *next
	const char *name
	UV min_depth
PPCODE:
	admix_reader t;
	Zero(&t, 1, admix_reader);
	t.r.name = name;
	t.r.min_depth = min_depth;
	t.r.on_header = admix_header;
	t.r.on_record = admix_record;
	t.g = sv_2mortal(newSVpvs(""));
	t.variants = (AV*)sv_2mortal((SV*)newAV());
	PUTBACK;
	vcf_read(aTHX_ next, &t.r);
	SPAGAIN;
	AV *called = (AV*)sv_2mortal((SV*)newAV());
	for (size_t i = 0; i < t.r.n; i++) av_push(called, newSVuv(t.called[i]));
	EXTEND(SP, 4);
	PUSHs(t.g);
	PUSHs(sv_2mortal(newRV_inc((SV*)t.variants)));
	PUSHs(sv_2mortal(newRV_inc((SV*)t.r.names)));
	PUSHs(sv_2mortal(newRV_inc((SV*)called)));

void
_admixture_fit(g, n, k, seed, max_iterations, tolerance)
	SV *g
	UV n
	UV k
	UV seed
	UV max_iterations
	NV tolerance
PPCODE:
	STRLEN len;
	const unsigned char *bytes = (const unsigned char*)SvPV_const(g, len);// not restrict: perl's buffer
	// named literally, since __func__ in an XSUB is XS_Cn__Bioinf__admixture_fit
	if (n == 0 || k == 0 || len % n) croak("_admixture_fit: %" UVuf " genotype bytes for %" UVuf " samples and K %" UVuf, (UV)len, n, k);// cannot happen: perl checks
	admix_fit a;
	a.g = bytes;
	a.n = (size_t)n;
	a.m = len / n;
	a.k = (size_t)k;
	if (a.k > ((size_t)-1 / sizeof(NV) / 4) / (a.n + a.m)) croak("_admixture_fit: %" UVuf " samples and %" UVuf " variants at K %" UVuf " are too many to fit", n, (UV)a.m, k);
	const size_t params = (a.n + a.m) * a.k;
	NV *th;
	Newx(th, params, NV);
	SAVEFREEPV(th);
	Newxz(a.twice, a.n, NV);
	SAVEFREEPV(a.twice);
	Newx(a.num, a.k, NV);
	SAVEFREEPV(a.num);
	Newx(a.den, a.k, NV);
	SAVEFREEPV(a.den);
	for (size_t j = 0; j < a.m; j++) {
		for (size_t i = 0; i < a.n; i++) {
			if (bytes[j * a.n + i] != ADMIX_MISSING) a.twice[i] += 2;
		}
	}
	admix_start(&a, th, (uint64_t)seed);
	UV iterations;
	bool converged;
	const NV ll = admix_run(aTHX_ &a, th, max_iterations, tolerance, &iterations, &converged);
	AV *q = (AV*)sv_2mortal((SV*)newAV()), *p = (AV*)sv_2mortal((SV*)newAV());
	for (size_t i = 0; i < a.n + a.m; i++) {
		AV *row = newAV();
		for (size_t l = 0; l < a.k; l++) av_push(row, newSVnv(th[i * a.k + l]));
		av_push(i < a.n ? q : p, newRV_noinc((SV*)row));
	}
	EXTEND(SP, 5);
	PUSHs(sv_2mortal(newRV_inc((SV*)q)));
	PUSHs(sv_2mortal(newRV_inc((SV*)p)));
	PUSHs(sv_2mortal(newSVnv(ll)));
	PUSHs(sv_2mortal(newSVuv(iterations)));
	PUSHs(sv_2mortal(newSVuv(converged ? 1 : 0)));
