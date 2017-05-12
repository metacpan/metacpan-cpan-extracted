
package Cisco::Reconfig;

@ISA = qw(Exporter);
@EXPORT = qw(readconfig);
@EXPORT_OK = qw(readconfig stringconfig $minus_one_indent_rx);

$VERSION = '0.911';

require Exporter;
use strict;
use Text::Tabs;
use Carp;
use Carp qw(verbose confess);
use IO::File;
use Scalar::Util qw(weaken);
my $iostrings;
our $allow_minus_one_indent = qr/class /;
our $allow_plus_one_indent = qr/service-policy /;
our $bad_indent_policy = 'DIE';


BEGIN	{
	eval " use IO::String ";
	$iostrings = $@ ? 0 : 1;
}


my $debug_get = 0;
my $debug_mget = 0;
my $debug_set = 0;
my $debug_context = 0;
my $debug_text = 0;
my $ddata = $debug_get 
	|| $debug_mget 
	|| $debug_set
	|| $debug_context
	|| $debug_text
	|| 0; # add debugging data to data structures

my $spec = qr{^ };
my $text = " text";
my $subs = " subs";
my $next = " next";
my $cntx = " cntx";
my $word = " word";
my $seqn = " seqn";
my $dupl = " dupl";
my $debg = " debg";
my $bloc = " bloc";
my $UNDEFDESC = "! undefined\n";
my $undef = bless { $debg => $UNDEFDESC, $text => '' }, __PACKAGE__;
my $dseq = "O0000000";
our $nonext;

my $line;
my $fh;

use overload 
	'bool' => \&defined,
	'""' => \&text,
	'fallback' => 1;

sub stringconfig
{
	Carp::croak 'IO::Strings need to be installed to use "stringconfig"'
		. ' install it or use "readconfig" instead.' unless $iostrings;
	readconfig(IO::String->new(join("\n",@_)));
}

sub readconfig
{
	my ($file) = @_;

	$fh = ref($file) ? $file : IO::File->new($file, "r");

	$line = <$fh>;
	return rc1(0, 'aaaa', $undef, "! whole enchalada\n");
}

sub rc1
{
	my ($indent, $seq, $parent, $dcon) = @_;
	my $last;
	my $config = bless { $bloc => 1 }, __PACKAGE__;

	$config->{$debg} = "BLOCK:$dseq:$dcon" if $ddata;

	$config->{$cntx} = $parent;
	weaken $config->{$cntx};

	$dseq++;
	my $prev;
	my $ciscobug;
	for(;$line;$prev = $line, $line = <$fh>) {
		$_ = $line;
		s/^( *)//;
		my $in = length($1);
		s/^(no +)//;
		my $no = $1;
		if ($in > $indent) {
			if ($last) {
				$last->{$subs} = rc1($in, "$last->{$seqn}aaa", $last, $line);
				undef $last;
				redo if $line;
			} else {
				# This really shouldn't happen.  But it does.  It's a violation of
				# the usual indentation rules.
				#
				# An exclamation marks a reset of the indentation to zero.
				#
				if ($indent + 1 == $in && $allow_plus_one_indent && $line =~ /^\s*$allow_plus_one_indent/) {
					$indent = $indent + 1;
					redo;
				}
				if ($indent != 0 || ($prev ne "!\n" && $prev !~ /^!.*<removed>$/)) {
					if ($bad_indent_policy eq 'IGNORE') {
						# okay then
					} elsif ($bad_indent_policy eq 'WARN') {
						warn "Unexpected indentation change <$.:$_>";
					} else {
						confess "Unexpected indentation change <$.:$_>";
					}
				}
				$ciscobug = 1;
				$indent = $in;
			}
		} elsif ($in < $indent) {
			if ($ciscobug && $in == 0) {
				$indent = 0;
			} elsif ($last && $indent - 1 == $in && $allow_minus_one_indent && $line =~ /^\s*$allow_minus_one_indent/) {
				confess unless $last->{$seqn};
				$last->{$subs} = rc1($in, "$last->{$seqn}aaa", $last, $line);
				undef $last;
				redo if $line;
			} else {
				return $config;
			}
		}
		next if /^$/;
		next if /^\s*!/;
		my $context = $config;
		my (@x) = split;
		my $owords = @x;
		while (@x && ref $context->{$x[0]}) {
			$context = $context->{$x[0]};
			shift @x;
		}
		if (! @x) {
			# A duplicate line.  Not fun.
			# As far as we know this can only occur as a remark inside 
			# filter list.
			# Q: what's the point of keeping track of these? Need to be
			# able to accurately dump filter list definitions
			#
			$context->{$dupl} = [] 
				unless $context->{$dupl};
			my $n = bless { 
				$ddata 
					? ( $debg => "$dseq:DUP:$line", 
					    $word => $context->{$word}, ) 
					: (),
			}, __PACKAGE__;
			$dseq++;

			push(@{$context->{$dupl}}, $n);
			$context = $n;
		} elsif (defined $context->{$x[0]}) {
			confess "already $.: '$x[0]' $line";
		}
		while (@x) {
			my $x = shift @x;
			confess unless defined $x;
			confess unless defined $dseq;
			$line = "" unless defined $line;
			$context = $context->{$x} = bless { 
				$ddata 
					? ( $debg => "$dseq:$x:$line", 
					    $word => $x, ) 
					: (),
			}, __PACKAGE__;
			$dseq++;
		}
		$context->{$seqn} = $seq++;
		$context->{$text} = $line;
		confess if $context->{$cntx};

		$context->{$cntx} = $config;
		weaken $context->{$cntx};

		unless ($nonext) {
			if ($last) {
				$last->{$next} = $context;
				weaken $last->{$next};
			} else {
				$config->{$next} = $context;
				weaken $config->{$next};
			}
		}

		$last = $context;

		if ($line && 
			($line =~ /(\^C)/ && $line !~ /\^C.*\^C/)
			|| 
			($line =~ /banner [a-z\-]+ ((?!\^C).+)/))
		{
			#
			# big special case for banners 'cause they don't follow
			# normal indenting rules
			#
			die unless defined $1;
			my $sep = qr/\Q$1\E/;
			my $sub = $last->{$subs} = bless { $bloc => 1 }, __PACKAGE__;
			$sub->{$cntx} = $last;
			weaken $sub->{$cntx};
			my $subnull = $sub->{''} = bless { $bloc => 1, $dupl => [] }, __PACKAGE__;
			$subnull->{$cntx} = $sub;
			weaken $subnull->{$cntx};
			for(;;) {
				$line = <$fh>;
				last unless $line;
				my $l = bless { 
					$ddata ? ( $debg => "$dseq:DUP:$line" ) : (),
				}, __PACKAGE__;
				$dseq++;
				$l->{$seqn} = $seq++;
				$l->{$text} = $line;
				$l->{$cntx} = $subnull;
				weaken($l->{$cntx});
				push(@{$subnull->{$dupl}}, $l);
				last if $line =~ /$sep[\r]?$/;
			} 
			warn "parse probably failed"
				unless $line && $line =~ /$sep[\r]?$/;
		}
	}
	return $config;
}

#sub word { $_[0]->{$word} };
sub block { $_[0]->{$bloc} }
sub seqn { $_[0]->{$seqn} || $_[0]->endpt->{$seqn} || confess };
sub subs { $_[0]->{$subs} || $_[0]->zoom->{$subs} || $undef };
sub next { $_[0]->{$next} || $_[0]->zoom->{$next} || $undef };
#sub undefined { $_[0] eq $undef }
#sub defined { $_[0] ne $undef }
sub defined { $_[0]->{$debg} ? $_[0]->{$debg} ne $UNDEFDESC : 1 }

sub destroy
{
	warn "Cisco::Reconfig::destroy is deprecated";
}

sub single
{
	my ($self) = @_;
	return $self if defined $self->{$text};
	my (@p) = grep(! /$spec/o, keys %$self);
	return undef if @p > 1;
	return $self unless @p;
	return $self->{$p[0]}->single || $self;
}

sub kids
{
	my ($self) = @_;
	return $self if ! $self;
	my (@p) = $self->sortit(grep(! /$spec/o, keys %$self));
	return $self if ! @p;
	return (map { $self->{$_} } @p);
}

sub zoom
{
	my ($self) = @_;
	return $self if defined $self->{$text};
	my (@p) = $self->sortit(grep(! /$spec/o, keys %$self));
	return $self if @p > 1;
	return $self unless @p;
	return $self->{$p[0]}->zoom;
}

sub endpt
{
	my ($self) = @_;
	return $self if ! $self;
	my (@p) = grep(! /$spec/o, keys %$self);
	return $self if defined($self->{$text}) && ! @p;
	confess unless @p;
	return $self->{$p[0]}->endpt;
}


sub text 
{
	my ($self) = @_;
	return '' unless $self;
	if (defined $self->{$text}) {
		return $debug_text
			? $self->{$word} . " " . $self->{$text}
			: $self->{$text};
	}
	my (@p) = $self->sortit(grep(! /$spec/o, keys %$self));
	if (@p > 1) {
		# 
		# This is nasty because the lines may not be ordered
		# in the tree-hiearchy used by Cisco::Reconfig
		#
		my %temp = map { $self->{$_}->sequenced_text(0) } @p;
		return join('', map { $temp{$_} } sort keys %temp);
	} elsif ($self->{$dupl}) {
		return join('', map { $_->{$word} . " " . $_->{$text} } @{$self->{$dupl}})
			if $debug_text;
		return join('', map { $_->{$text} } @{$self->{$dupl}});
	}
	confess unless @p;
	return $self->{$p[0]}->text;
}

sub sequenced_text
{
	my ($self, $all) = @_;
	my @t = ();
	if (defined $self->{$text}) {
		push(@t, $debug_text
			? ($self->seqn => $self->{$word} . " " . $self->{$text})
			: ($self->seqn => $self->{$text}));
	}
	if (exists $self->{$dupl}) {
		push (@t, $debug_text
			? map { $_->seqn => $_->{$word} . " " . $_->{$text} } @{$self->{$dupl}}
			: map { $_->seqn => $_->{$text} } @{$self->{$dupl}});
	}
	my (@p) = $self->sortit(grep(! /$spec/o, keys %$self));
	if (@p) {
		# 
		# This is nasty because the lines may not be ordered
		# in the tree-hiearchy used by Cisco::Reconfig
		#
		return (@t, map { $self->{$_}->sequenced_text($all) } @p);
	} 
	push(@t, $self->{$subs}->sequenced_text($all))
		if $all && $self->{$subs};
	return @t if @t;
	confess unless @p;
	return $self->{$p[0]}->sequenced_text($all);
}

sub alltext 
{
	my ($self) = @_;
	return '' unless $self;
	my %temp = $self->sequenced_text(1);
	return join('', map { $temp{$_} } sort keys %temp);
}

sub chomptext
{
	my ($self) = @_;
	my $t = $self->text;
	chomp($t);
	return $t;
}

sub returns
{
	my (@o) = @_;
	for my $o (@o) {
		$o .= "\n" 
			if defined($o) && $o !~ /\n$/;
	}
	return $o[0] unless wantarray;
	return @o;
}

sub openangle
{
	my (@l) = grep(defined && /\S/, @_);
	my $x = 0;
	for my $l (@l) { 
		substr($l, 0, 0) = (' ' x $x++);
	}
	return $l[0] unless wantarray;
	return @l;
}

sub closeangle
{
	my (@l) = grep(defined && /\S/, @_);
	my $x = $#l;
	for my $l (@l) { 
		substr($l, 0, 0) = (' ' x $x--);
	}
	return $l[0] unless wantarray;
	return @l;
}

sub context 
{
	defined($_[0]->{$cntx}) 
		? $_[0]->{$cntx}
		: $_[0]->endpt->{$cntx} 
			|| ($_[0] ? confess "$_[0]" : $undef) 
};

#
# interface Loopback7
#  ip address x y
#

sub setcontext
{
	my ($self, @extras) = @_;
	print STDERR "\nSETCONTEXT\n" if $debug_context;
	unless ($self->block) {
		print STDERR "\nNOT_A_BLOCK $self->{$debg}\n" if $debug_context;
		$self = $self->context;
	}
	printf STDERR "\nSELF %sCONTEXT %sCCONTEXT %sEXTRAS$#extras @extras\n",
		$self->{$debg}, $self->context->{$debg},
		$self->context->context->{$debg}
		if $debug_context;
	my $x = $self->context;
	return (grep defined, 
		$x->context->setcontext, 
		trim($x->zoom->{$text}), 
		@extras) 
			if $x;
	return @extras;
}
 
sub contextcount 
{ 
	my $self = shift;
	my (@a) = $self->setcontext(@_); 
	printf STDERR "CONTEXTCOUNT = %d\n", scalar(@a) if $debug_context;
	print STDERR map { "CC: $_\n" } @a if $debug_context;
	return scalar(@a); 
}

sub unsetcontext 
{ 
	my $self = shift;
	return (("exit") x $self->contextcount(@_));
}

sub teql
{
	my ($self, $b) = @_;
	my $a = $self->text;
	$a =~ s/^\s+/ /g;
	$a =~ s/^ //;
	$a =~ s/ $//;
	chomp($a);
	$b =~ s/^\s+/ /g;
	$b =~ s/^ //;
	$b =~ s/ $//;
	chomp($b);
	return $a eq $b;
}

sub set
{
	my $self = shift;
	my $new = pop;
	my (@designators) = @_;
	#my ($self, $designator, $new) = @_;
	print STDERR "\nSET\n" if $debug_set;
	return undef unless $self;
	my $old;
	#my @designators;
	print STDERR "\nSELF $self->{$debg}" if $debug_set;
	# move into the block if possible
	$self = $self->subs
		if $self->subs;
	print STDERR "\nSELF $self->{$debg}" if $debug_set;
	#if (ref $designator eq 'ARRAY') {
	#	@designators = @$designator;
	#	$old = $self->get(@designators);
	#	$designator = pop(@designators);
	#} elsif ($designator) {
	#	$old = $self->get($designator);
	#} else {
	#	$old = $self;
	#}
	my $designator;
	if (@designators) {
		$old = $self->get(@designators);
		$designator = pop(@designators);
	} else {
		$old = $self;
	}
	print STDERR "\nOLD $old->{$debg}" if $debug_set;
	my (@lines) = expand(grep(/./, split(/\n/, $new)));
	if ($lines[0] =~ /^(\s+)/) {
		my $ls = $1;
		my $m = 1;
		map { substr($_, 0, length($ls)) eq $ls or $m = 0 } @lines;
		map { substr($_, 0, length($ls)) = '' } @lines
			if $m;
	}
	my $indent = (' ' x $self->contextcount(@designators));
	for $_ (@lines) {
		s/(\S)\s+/$1 /g;
		s/\s+$//;
		$_ = 'exit' if /^\s*!\s*$/;
		$_ = "$indent$_";
	}
	print STDERR "SET TO {\n@lines\n}\n" if $debug_set;
	my $desig = shift(@lines);
	my @o;
	undef $old 
		if ! $old;
	if (! $old) {
		print STDERR "NO OLD\n" if $debug_set;
		push(@o, openangle($self->setcontext(@designators)));
		push(@o, $desig);
	} elsif (! $designator && ! looks_like_a_block($desig,@lines)) {
		if ($self->block && $self->context) {
			unshift(@lines, $desig);
			$old = $self->context;
			undef $desig;
		} else {
			unshift(@lines, $desig);
			print STDERR "IN NASTY BIT\n" if $debug_set;
			# 
			# this is a messy situation: we've got a random
			# block of stuff to set inside a random block.
			# In theorey we could avoid the die, I'll leave
			# that as an exercise for the reader.
			# 
			confess "You cannot set nested configurations with set(undef, \$config) -- use a designator on the set method"
				if grep(/^$indent\s/, @lines);
			my (@t) = split(/\n/, $self->text);
			my (%t);
			@t{strim(@t)} = @t;
			while (@lines) {
				my $l = strim(shift(@lines));
				if ($t{$l}) {
					delete $t{$l};
				} else {
					push(@o, "$indent$l");
				}
			}
			for my $k (keys %t) {
				unshift(@o, iinvert($indent, $k));
			}
			unshift(@o, $self->setcontext)
				if @o;
		}
	} elsif ($old->teql($desig)) { 
		print STDERR "DESIGNATOR EQUAL\n" if $debug_set;
		# okay
	} else {
		print STDERR "DESIGNATOR DIFERENT\n" if $debug_set;
		push(@o, openangle($self->setcontext(@designators)));
		if (defined $designator) {
			push(@o, iinvert($indent, $designator));
		} else {
			push(@o, iinvert($indent, split(/\n/, $self->text)));
		} 
		push(@o, $desig);
	}
	if (@lines) {
		if ($old && ! @o && $old->subs && $old->subs->next) {
			print STDERR "OLD= $old->{$debg}" if $debug_set;
			my $ok = 1;
			my $f = $old->subs->next;
			print STDERR "F= $f->{$debg}" if $debug_set;
			for my $l (@lines) {
				next if $l =~ /^\s*exit\s*$/;
				next if $f->teql($l);
				print STDERR "LINE DIFF ON $l\n" if $debug_set;
				$ok = 0;
				last;
			} continue {
				$f = $f->next;
				print STDERR "F= $f->{$debg}" if $debug_set;
			}
			if (! $ok || $f) {
				push(@o, openangle($self->setcontext(@designators)));
				push(@o, iinvert($indent, $designator));
				push(@o, $desig);
			}
		}
		push(@o, @lines) if @o;
	}
	@o = grep(defined, @o);
	push(@o, closeangle($self->unsetcontext(@designators)))
		if @o;
	return join('', returns(@o)) unless wantarray;
	return returns(@o);
}

sub looks_like_a_block
{
	my ($first, @l) = @_;
	my $last = pop(@l);
	return 1 if ! defined $last;
	return 0 if grep(/^\S/, @l);
	return 0 if $first =~ /^\s/;
	return 0 if $last =~ /^\s/;
	return 1;
}

sub iinvert
{
	my ($indent,@l) = @_;
	confess unless @l;
	for $_ (@l) {
		next unless defined;
		s/^\s*no /$indent/ or s/^\s*(\S)/${indent}no $1/
	}
	return $l[0] unless wantarray;
	return @l;
}

sub all
{
	my ($self, $regex) = @_;
	$self = $self->zoom;
	return (map { $self->{$_} } $self->sortit(grep(/$regex/ && ! /$spec/o, keys %$self)))
		if $regex;
	return (map { $self->{$_} } $self->sortit(grep(! /$spec/o, keys %$self)));
}

sub get
{
	my ($self, @designators) = @_;
	return $self->mget(@designators)
		if wantarray && @designators > 1;

	print STDERR "\nGET <@designators> $self->{$debg}" if $debug_get;


	return $self unless $self;
	my $zoom = $self->zoom->subs;
	$self = $zoom if $zoom;

	print STDERR "\nZOOMSUB $self->{$debg}" if $debug_get;

	while (@designators) {
		my $designator = shift(@designators);
#		$self = $self->zoom;
	#	$self = $self->single || $self;
		print STDERR "\nDESIGNATOR: $designator.  ZOOMED: $self->{$debg}\n"
			if $debug_get;
		for my $d (split(' ',$designator)) {
			print STDERR "\nDO WE HAVE A: $d?\n" if $debug_get;
			return $undef unless $self->{$d};
			$self = $self->{$d};
			print STDERR "\nWE DO: $self->{$debg}\n" if $debug_get;
		}
		last unless @designators;
		if ($self->single) {
			$self = $self->subs;
			print STDERR "\nSINGLETON: $self->{$debg}\n" if $debug_get;
		} else {
			print STDERR "\nNOT SINGLE\n" if $debug_get;
			return $undef;
		}
	}
	print STDERR "\nDONE\n" if $debug_get;
	if (wantarray) {
		$self = $self->zoom;
		my (@k) = $self->kids;
		return @k if @k;
		return $self;
	}
	return $self;
}

sub strim
{
	my (@l) = @_;
	for $_ (@l) {
		s/^\s+//;
		s/\s+$//;
		s/\n$//;
	}
	return $l[0] unless wantarray;
	return @l;
}

sub trim
{
	my (@l) = @_;
	for $_ (@l) {
		s/^\s+//;
		s/\s+$//;
	}
	return $l[0] unless wantarray;
	return @l;
}

sub display
{
	my ($self) = @_;
	my @o;
	push(@o, $self->setcontext);
	push(@o, trim($self->single->{$text}))
		if $self->single && $self->single->{$text}
			&& $self->subs->undefined;
	push(@o, "! the whole enchalada")
		if $self->context->undefined;
	my (@r) = returns(openangle(@o));
	return @r if wantarray;
	return join('', @r);
}

sub callerlevels
{
	my $n = 1;
	1 while caller($n++);
	return $n;
}

sub mget
{
	my ($self, @designators) = @_;

	my $cl = callerlevels;
	my @newset;
	if (@designators > 1) {

		print STDERR "\nGET$cl $designators[0]----------\n" if $debug_mget;

		my (@set) = $self->get(shift @designators);
		for my $item (@set) {

			print STDERR "\nMGET$cl $item ----------\n" if $debug_mget;
			print STDERR "\nMGET$cl $item->{$debg}\n" if $debug_mget;

			my (@got) = $item->mget(@designators);

			print STDERR map { "\nRESULTS$cl: $_->{$debg}\n" } @got
				if $debug_mget;

			push(@newset, @got);
		}
	} else {

		print STDERR "\nxGET$cl $designators[0] -------\n" if $debug_mget;

		(@newset) = $self->get(shift @designators);

		print STDERR map { "\nxRESULTS$cl: $_->{$debg}\n" } @newset
			if $debug_mget;

	}
	return @newset;
}

sub sortit
{
	my $self = shift;
	return sort { $self->{$a}->seqn cmp $self->{$b}->seqn } @_;
}

1;

