#line 1 "inc/Locale/Maketext/Simple.pm - /opt/lib/perl5/site_perl/5.8.3/Locale/Maketext/Simple.pm"
# $File: //member/autrijus/Locale-Maketext-Simple/lib/Locale/Maketext/Simple.pm $ $Author: autrijus $
# $Revision: #17 $ $Change: 9922 $ $DateTime: 2004/02/06 11:13:31 $

package Locale::Maketext::Simple;
$Locale::Maketext::Simple::VERSION = '0.11';

use strict;

#line 94

sub import {
    my ($class, %args) = @_;

    $args{Class}    ||= caller;
    $args{Style}    ||= 'maketext';
    $args{Export}   ||= 'loc';
    $args{Subclass} ||= 'I18N';

    my ($loc, $loc_lang) = $class->load_loc(%args);
    $loc ||= $class->default_loc(%args);

    no strict 'refs';
    *{caller(0) . "::$args{Export}"} = $loc if $args{Export};
    *{caller(0) . "::$args{Export}_lang"} = $loc_lang || sub { 1 };
}

my %Loc;

sub reload_loc { %Loc = () }

sub load_loc {
    my ($class, %args) = @_;

    my $pkg = join('::', $args{Class}, $args{Subclass});
    return $Loc{$pkg} if exists $Loc{$pkg};

    eval { require Locale::Maketext::Lexicon; 1 }   or return;
    $Locale::Maketext::Lexicon::VERSION > 0.20	    or return;
    eval { require File::Spec; 1 }		    or return;

    my $path = $args{Path} || $class->auto_path($args{Class}) or return;
    my $pattern = File::Spec->catfile($path, '*.[pm]o');
    my $decode = $args{Decode} || 0;

    $pattern =~ s{\\}{/}g; # to counter win32 paths

    eval "
	package $pkg;
	use base 'Locale::Maketext';
        %${pkg}::Lexicon = ( '_AUTO' => 1 );
	Locale::Maketext::Lexicon->import({
	    'i-default' => [ 'Auto' ],
	    '*'	=> [ Gettext => \$pattern ],
	    _decode => \$decode,
	});
	*tense = sub { \$_[1] . ((\$_[2] eq 'present') ? 'ing' : 'ed') }
	    unless defined &tense;

	1;
    " or die $@;
    
    my $lh = eval { $pkg->get_handle } or return;
    my $style = lc($args{Style});
    if ($style eq 'maketext') {
	$Loc{$pkg} = sub {
	    $lh->maketext(@_)
	};
    }
    elsif ($style eq 'gettext') {
	$Loc{$pkg} = sub {
	    my $str = shift;
	    $str =~ s/[\~\[\]]/~$&/g;
	    $str =~ s{(^|[^%\\])%([A-Za-z#*]\w*)\(([^\)]*)\)}
		     {"$1\[$2,"._unescape($3)."]"}eg;
	    $str =~ s/(^|[^%\\])%(\d+|\*)/$1\[_$2]/g;
	    return $lh->maketext($str, @_);
	};
    }
    else {
	die "Unknown Style: $style";
    }

    return $Loc{$pkg}, sub {
	$lh = $pkg->get_handle(@_);
	$lh = $pkg->get_handle(@_);
    };
}

sub default_loc {
    my ($self, %args) = @_;
    my $style = lc($args{Style});
    if ($style eq 'maketext') {
	return sub {
	    my $str = shift;
	    $str =~ s/((?<!~)(?:~~)*)\[_(\d+)\]/$1%$2/g;
	    $str =~ s{((?<!~)(?:~~)*)\[([A-Za-z#*]\w*),([^\]]+)\]}
		     {"$1%$2("._escape($3).")"}eg;
	    $str =~ s/~([\[\]])/$1/g;
	    _default_gettext($str, @_);
	};
    }
    elsif ($style eq 'gettext') {
	return \&_default_gettext;
    }
    else {
	die "Unknown Style: $style";
    }
}

sub _default_gettext {
    my $str = shift;
    $str =~ s{
	%			# leading symbol
	(?:			# either one of
	    \d+			#   a digit, like %1
	    |			#     or
	    (\w+)\(		#   a function call -- 1
		(?:		#     either
		    %\d+	#	an interpolation
		    |		#     or
		    ([^,]*)	#	some string -- 2
		)		#     end either
		(?:		#     maybe followed
		    ,		#       by a comma
		    ([^),]*)	#       and a param -- 3
		)?		#     end maybe
		(?:		#     maybe followed
		    ,		#       by another comma
		    ([^),]*)	#       and a param -- 4
		)?		#     end maybe
		[^)]*		#     and other ignorable params
	    \)			#   closing function call
	)			# closing either one of
    }{
	my $digit = $2 || shift;
	$digit . (
	    $1 ? (
		($1 eq 'tense') ? (($3 eq 'present') ? 'ing' : 'ed') :
		($1 eq 'quant') ? ' ' . (($digit > 1) ? ($4 || "$3s") : $3) :
		''
	    ) : ''
	);
    }egx;
    return $str;
};

sub _escape {
    my $text = shift;
    $text =~ s/\b_(\d+)/%$1/;
    return $text;
}

sub _unescape {
    my $str = shift;
    $str =~ s/(^|,)%(\d+|\*)(,|$)/$1_$2$3/g;
    return $str;
}

sub auto_path {
    my ($self, $calldir) = @_;
    $calldir =~ s#::#/#g;
    my $path = $INC{$calldir . '.pm'} or return;

    # Try absolute path name.
    if ($^O eq 'MacOS') {
	(my $malldir = $calldir) =~ tr#/#:#;
	$path =~ s#^(.*)$malldir\.pm\z#$1auto:$malldir:#s;
    } else {
	$path =~ s#^(.*)$calldir\.pm\z#$1auto/$calldir/#;
    }

    return $path if -d $path;

    # If that failed, try relative path with normal @INC searching.
    $path = "auto/$calldir/";
    foreach my $inc (@INC) {
	return "$inc/$path" if -d "$inc/$path";
    }

    return;
}

1;

#line 293
