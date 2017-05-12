package AutoXS::Header;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.02';

sub WriteAutoXSHeader {
  my $filename = shift;
  if (defined $filename and $filename eq 'AutoXS::Header') {
    $filename = shift;
  }
  $filename = 'AutoXS.h' if not defined $filename;
  open my $fh, '>', $filename
    or die "Could not open '$filename' for writing: $!";
  print $fh "/* AutoXS::Header version '$VERSION' */\n";
  print $fh <<'AUTOXSHEADERHEREDOC';
typedef struct {
  U32 hash;
  SV* key;
} autoxs_hashkey;

/* prototype section */

I32 get_hashkey_index(const char* key, const I32 len);
I32 _new_hashkey();
void _resize_array(I32** array, unsigned int* len, unsigned int newlen);
void _resize_array_init(I32** array, unsigned int* len, unsigned int newlen, I32 init);
I32 _new_internal_arrayindex();
I32 get_internal_array_index(I32 object_ary_idx);

/* initialization section */

unsigned int AutoXS_no_hashkeys = 0;
unsigned int AutoXS_free_hashkey_no = 0;
autoxs_hashkey* AutoXS_hashkeys = NULL;
HV* AutoXS_reverse_hashkeys = NULL;

unsigned int AutoXS_no_arrayindices = 0;
unsigned int AutoXS_free_arrayindices_no = 0;
I32* AutoXS_arrayindices = NULL;

unsigned int AutoXS_reverse_arrayindices_length = 0;
I32* AutoXS_reverse_arrayindices = NULL;


/* implementation section */

I32 get_hashkey_index(const char* key, const I32 len) {
  I32 index;

  /* init */
  if (AutoXS_reverse_hashkeys == NULL)
    AutoXS_reverse_hashkeys = newHV();

  index = 0;
  if ( hv_exists(AutoXS_reverse_hashkeys, key, len) ) {
    SV** index_sv = hv_fetch(AutoXS_reverse_hashkeys, key, len, 0);

    /* simply return the index that corresponds to an earlier
     * use with the same hash key name */

    if ( (index_sv == NULL) || (!SvIOK(*index_sv)) ) {
      /* shouldn't happen */
      index = _new_hashkey();
    }
    else /* Note to self: Check that this I32 cast is sane */
      return (I32)SvIVX(*index_sv);
  }
  else /* does not exist */
    index = _new_hashkey();

  /* store the new hash key in the reverse lookup table */
  hv_store(AutoXS_reverse_hashkeys, key, len, newSViv(index), 0);
  return index;
}

/* this is private, call get_hashkey_index instead */
I32 _new_hashkey() {
  if (AutoXS_no_hashkeys == AutoXS_free_hashkey_no) {
    unsigned int extend = 1 + AutoXS_no_hashkeys * 2;
    /*printf("extending hashkey storage by %u\n", extend);*/
    unsigned int oldsize = AutoXS_no_hashkeys * sizeof(autoxs_hashkey);
    /*printf("previous data size %u\n", oldsize);*/
    autoxs_hashkey* tmphashkeys =
      (autoxs_hashkey*) malloc( oldsize + extend * sizeof(autoxs_hashkey) );
    memcpy(tmphashkeys, AutoXS_hashkeys, oldsize);
    free(AutoXS_hashkeys);
    AutoXS_hashkeys = tmphashkeys;
    AutoXS_no_hashkeys += extend;
  }
  return AutoXS_free_hashkey_no++;
}


void _resize_array(I32** array, unsigned int* len, unsigned int newlen) {
  unsigned int oldsize = *len * sizeof(I32);
  I32* tmparraymap = (I32*) malloc( newlen * sizeof(I32) );
  memcpy(tmparraymap, *array, oldsize);
  free(*array);
  *array = tmparraymap;
  *len = newlen;
}

void _resize_array_init(I32** array, unsigned int* len, unsigned int newlen, I32 init) {
  unsigned int i;
  unsigned int oldsize = *len * sizeof(I32);
  I32* tmparraymap = (I32*) malloc( newlen * sizeof(I32) );
  memcpy(tmparraymap, *array, oldsize);
  free(*array);
  *array = tmparraymap;
  for (i = *len; i < newlen; ++i)
    (*array)[i] = init;
  *len = newlen;
}


/* this is private, call get_array_index instead */
I32 _new_internal_arrayindex() {
  if (AutoXS_no_arrayindices == AutoXS_free_arrayindices_no) {
    unsigned int extend = 2 + AutoXS_no_arrayindices * 2;
    /*printf("extending array index storage by %u\n", extend);*/
    /*printf("previous data size %u\n", oldsize);*/
    _resize_array(&AutoXS_arrayindices, &AutoXS_no_arrayindices, extend);
  }
  return AutoXS_free_arrayindices_no++;
}

I32 get_internal_array_index(I32 object_ary_idx) {
  I32 new_index;

  if (AutoXS_reverse_arrayindices_length <= (unsigned int)object_ary_idx)
    _resize_array_init( &AutoXS_reverse_arrayindices,
                        &AutoXS_reverse_arrayindices_length,
                        object_ary_idx+1, -1 );

  /* -1 == "undef" */
  if (AutoXS_reverse_arrayindices[object_ary_idx] > -1)
    return AutoXS_reverse_arrayindices[object_ary_idx];

  new_index = _new_internal_arrayindex();
  AutoXS_reverse_arrayindices[object_ary_idx] = new_index;
  return new_index;
}
AUTOXSHEADERHEREDOC
}

1;
__END__

=head1 NAME

AutoXS::Header - Container for the AutoXS header files

=head1 SYNOPSIS

  # potentially in your Makefile.PL
  sub MY::post_constants {
    # Write header as AutoXS.h in current directory
    return <<'MAKE_FRAG';
  linkext ::
          $(PERL) -MAutoXS::Header -e AutoXS::Header::WriteAutoXSHeader
  # note the tab character in the previous line!

  MAKE_FRAG
  }

=head1 DESCRIPTION

This module is a simple container for the newest version of the L<AutoXS> header
file C<AutoXS.h>.

=head1 SEE ALSO

L<AutoXS>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
