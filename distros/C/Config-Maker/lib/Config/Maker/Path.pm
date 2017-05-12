package Config::Maker::Path;

use utf8;
use warnings;
use strict;

use Carp;

require Config::Maker::Path::Root;
require Config::Maker::Path::AnyPath;
require Config::Maker::Path::This;
require Config::Maker::Path::Parent;
require Config::Maker::Path::Meta;

use overload
    'cmp' => \&Config::Maker::truecmp,
    '<=>' => \&Config::Maker::truecmp,
    '""' => 'str',
    fallback => 1;

our $parser = $Config::Maker::parser;

our %paths; # Cache for paths...

our %checks; # For [$if$] directive...

# Coversion of expressions to regexes and coderefs:

sub _glob_to_re {
    local $_ = $_[0];

    /[.+^\-\$]/	? "\\$_" :
    /\{/	? "(?:" :
    /\}/	? ")" :
    /\*/	? ".*" :
    /\?/	? "." : 
		  $_;
}

sub glob_to_re {
    my ($self, $patt) = @_;

    return qr/.*/ if (!defined $patt);
    return qr/$patt/ if ($patt =~ s/^RE://);

    $patt =~ s/([^\\])|(\\.)/defined $1 ? _glob_to_re($1) : $2/eg;
    qr/^$patt$/;
}

sub code_to_sub {
    my ($self, $code) = @_;

    return sub { 1; } unless $code;
    Config::Maker::DBG("Code-to-sub: qq{$code}");
    $code =~ s/\A\(//;
    $code =~ s/\)\Z//;
    my $sub = Config::Maker::exe("sub { $code; };");
    return $sub;
}

# Common argument parsing:

sub bhash {
    my ($class, $keys) = splice @_, 0, 2;
    $keys = +{ map { $_ => 1; } @$keys } if(ref($keys) eq 'ARRAY');
    my %hash = (ref($_[0]) eq 'HASH' ? %{$_[0]} : @_);

    for(keys %hash) {
	croak "Unknown argument $_"
	    unless $keys->{$_};
    }
    bless \%hash, $class;
}

# Public interface:

sub new {
    my $self = shift->bhash([qw/-type -value -code -tail/], @_);

    $self->{-text} = '';
    $self->{-text} .= $self->{-type} if $self->{-type};
    $self->{-text} .= ':' . $self->{-value} if $self->{-value};
    $self->{-text} .= $self->{-code} if $self->{-code};

    $self->{-type} = $self->glob_to_re($self->{-type});
    $self->{-value} = $self->glob_to_re($self->{-value});
    $self->{-code} = $self->code_to_sub($self->{-code});

    return $self;
}

sub make {
    my ($class, $text) = @_;
#D#    DBG "Making path from `$text'";
    return $text if UNIVERSAL::isa($text, __PACKAGE__);
    return $paths{$text} if($paths{$text});
    $paths{$text} = $parser->path_whole($text)
	or croak "Invalid path: $text";
}

sub match {
    my ($self, $from) = @_;

    grep {
#	no warnings 'uninitialized'; # NOTEME
	($_->{-type} =~ /$self->{-type}/)
	&& ($_->{-value} =~ /$self->{-value}/)
	&& ($self->{-code}->())
   } @{$from->{-children}}
}

sub find {
    my ($self, $from, $gather) = @_;
    $gather ||= [];

#D#    DBG "Pattern $self find in ".$from->id;
    if($self->{-tail}) {
	$self->{-tail}->find($_, $gather) for $self->match($from);
    } else {
	push @$gather, ($self->match($from));
    }
#D#    DBG "Returning: `" . join("', `", map $_->id, @$gather) . "'";

    return $gather;
}

sub text {
    $_[0]->{-text};
}

sub str {
    my ($self) = @_;
    $self->text . ($self->{-tail} ? '/' . $self->{-tail}->str : '');
}

sub _findtimes {
    confess "$_[1] can't ->find" unless UNIVERSAL::can($_[1], 'find');
    my $r = $_[1]->find($_[0]);
    return 0 if @$r < $_[2];
    return 1 if @_ == 3;
    return 0 if @$r > $_[3];
    return 1;
}

BEGIN { # Constants must be done early enough...
    %checks = (
	none => sub { _findtimes($_, @_, 0,0); },
	unique =>  sub { _findtimes($_, @_,0,1); },
	one =>  sub { _findtimes($_, @_,1,1); },
	exists => sub { _findtimes($_, @_,1); },
	any => sub { 1; },
    );
}

1;

__END__

=head1 NAME

Config::Maker::Path - Selects elements from config.

=head1 SYNOPSIS

  use Config::Maker

  $path = Config::Maker::Path->new(
    -type => $typepattern,
    -value => $valuepattern,
    -code => $perlcode,
    -tail => $rest);

  $path = Config::Maker::Path::AnyPath->new(
    -tail => $rest);

  $path = Config::Maker::Path::Root->new(
    -tail => $rest);

  $path = Config::Maker::Path::Parent->new(
    -tail => $rest);

  $path = Config::Maker::Path::This->new(
    -tail => $rest);

  $path = Config::Maker::Path->make($pathstring)

  $path->find($config_element);

  $config_element->get($path);
  $config_element->get($pathstring);

=head1 DESCRIPTION

Paths are used to select config elements to put in a template.

Path is a list of component. Each of them can be either normal (of type
C<Config::Maker::Path>), or special (of some subclass type). Each component,
when matched from some configuration element, selects some set of matching
elemens. From these elements, rest of the path is matched.

A normal component specifies a type pattern, a value pattern and a match
code. A config element matches such component if it is a child of staring
element, it's type matches given pattern, it's value matches given pattern and
the code returns true.  All of these have defaults. Default patterns are
C<*> and default code is C<1>. Note, that the code is not a closure, but rather
a string, that is wrapped to a closure automagicaly.

The special components are C<AnyPath>, C<Root>, C<Parent> and C<This>.

The C<AnyPath> element matches starting element and all it's descendants (even
indirect).

The C<Root> always returns the global $Config::Maker::Eval::config->{root}
element, no matter what the starting element was.

The C<Parent> matches parent of starting element.

The C<This> matches the starting element.

Matching is done recursively using the C<find> and C<match> methods. The
C<find> method calls C<match> method of given component to get list of matching
elements and then recurses to each of them if C<-tail> is defined, and pushes
them in the accumulator otherwise. It returns the acumulator (an arrayref).

There are two construcotrs for paths. The C<new> constructor needs parsed
specification. It however builds regexes and coderefs from strings itself.

The higher-level C<make> constructor takes a string describing whole path (see
L<configit> for grammar description), parses it and builds the path. It uses
L<Config::Maker::Grammar> to do the dirty work.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: 57f77d61-a3ce-4811-b704-76be3e1a41d7
