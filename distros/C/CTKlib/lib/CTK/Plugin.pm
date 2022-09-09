package CTK::Plugin;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin - Base class for CTK plugins writing

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    package CTK::Plugin::Foo;
    use strict;
    use base qw/CTK::Plugin/;

    sub init {
        my $self = shift; # It is CTK object!
        ...
        return 1; # or 0 if errors
    }

    __PACKAGE__->register_method(
        namespace => "CTK", # Optional. Default: CTK
        method    => "foo",
        callback  => sub {
            my $self = shift; # It is CTK object!
            ...
            return 1;
    });

    1;

=head1 DESCRIPTION

A "plugin" for the CTK is simply a Perl module which exists in a known package
location (CTK::Plugin::*) and conforms to a our standard, allowing it to be
loaded and used automatically. See L<CTK::Plugin::Test> for example

=head2 init

Allows you to initialize your plugin

The method is automatically call in CTK constructor. The first param is CTK object.
The method MUST return 0 in case of failure or 1 in case of successful initialization

=head2 register_method

    __PACKAGE__->register_method(
        namespace => "CTK", # Optional. Default: CTK
        method    => "mothod_name",
        callback  => sub {
            my $self = shift; # It is CTK object!
            ...
            return 1;
    });

Allows register the method that will be linked with Your plugin callback function

=head1 HISTORY

=over 8

=item B<1.00 Wed  1 May 00:20:20 MSK 2019>

Init version

=back

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::Plugin::Test>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use constant {
    NAMESPACE => "CTK",
};

sub init { 1 }
sub register_method {
    my $package = shift;
    my %meta = @_;
    my $namespace = $meta{namespace} || NAMESPACE;
    my $callback = $meta{callback} || sub { 1 };
    return unless ref($callback) eq "CODE";
    my $method = $meta{method};
    return unless $method;
    my $ff = sprintf("%s::%s", $namespace, $method);

    # Check
    return if do { no strict 'refs'; defined &{$ff} };

    # Create method!
    do {
        no strict 'refs';
        *{$ff} = \&$callback;
    };
    return 1;
}

1;

__END__