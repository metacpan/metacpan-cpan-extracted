package Config::Maker::Eval;

use utf8;
use warnings;
use strict;

use Carp;
require Config::Maker::Path;

=head1 NAME

Config::Maker::Eval - Environment to run user-code in Config::Maker

=head1 SYNOPSIS

  # In perl-code in metaconfig, config or template

  Get($path)
  Get($path, $default)
  Get1($path)
  Get1($path, $default)
  Value($path_or_option)
  Type($path_or_option)
  Exists($path)
  Unique($path)
  One($path)

=head1 DESCRIPTION

All user code executed by Config::Maker, whether read from metaconfig, config
or template, is executed in Config::Maker::Eval package. In that package,
following convenience functions are available. Note, that when relative path is
specified to any of them, it is resolved relative to the current topic ($_).
Thus it must contain a config element.

=over 4

=item Get(I<$path>, I<[$default]>)

Resolves I<$path> and returns list of results, or the first result in scalar
context. If I<$default> is given, and the path does not match, I<$default> is
returned.

=cut

sub Get {
    my $path = shift;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($_);
    return wantarray ? @_ : $_[0] unless @$res;
    return wantarray ? @$res : $res->[0];
}

=item Get1(I<$path>, I<[$default]>)

Resolves path and returns the result. If there is more than one result, or if
the path does not match and no default is given, throws an error.

=cut

sub Get1 {
    my $path = shift;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($_);
    croak "$path should have at most one result" if @$res > 1;
    croak "$path should have a result" unless @$res || @_ == 1;
    return @$res ? $res->[0] : $_[0];
}

=item Value(I<$path_or_option>)

Returns value of config element or matching path (exactly one must match). If
no arguments given, returns value of $_.

=cut

sub Value {
    my $arg = (@_ ? $_[0] : $_);
    if(UNIVERSAL::isa($arg, 'Config::Maker::Option')) {
	return $arg->{-value};
    } else {
	return Get1($arg)->{-value};
    }
}

=item Type(I<$path_or_option>)

Returns type of config element or matching path (exactly one must match). If
no arguments given, returns type of $_.

=cut

sub Type {
    my $arg = (@_ ? $_[0] : $_);
    if(UNIVERSAL::isa($arg, 'Config::Maker::Option')) {
	return $arg->{-type};
    } else {
	return Get1($arg)->{-type};
    }
}

=item Exists(I<$path>)

Returns true iff I<$path> matches at least one config element.

=cut

sub Exists {
    my @res = Get($_[0]);
    return @res > 0;
}

=item Unique(I<$path>)

Returns true iff I<$path> matches at most one config element.

=cut

sub Unique {
    my @res = Get($_[0]);
    return @res <= 1;
}

=item One(I<$path>)

Returns true iff I<$path> matches exactly one config element.

=cut

sub One {
    my @res = Get($_[0]);
    return @res == 1;
}

=back

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut

1;

__END__
# arch-tag: ccde4ef3-3389-4710-8b6f-5ead302d69a3
