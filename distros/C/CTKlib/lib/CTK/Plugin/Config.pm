package CTK::Plugin::Config;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Config - Configuration plugin

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    use CTK::ConfGenUtil;

    my $ctk = new CTK(
            plugins     => "config",
            configfile  => "test.conf",
            root        => ".",
            confopts    => {... Config::General options ...},
        );
    print $ctk->config("foo");
    print value($ctk->config(), "myinc/Test/val2")

=head1 DESCRIPTION

Configuration plugin

=over 8

=item B<configfile>

Specifies absolute or relative path to config-file

See L<CTK::Configuration/"config">

=item B<confopts>

Options of L<Config::General>

=item B<root>

Specifies absolute or relative path to config-dir. Root dir of project

See L<CTK::Configuration> and L<CTK/"root">

=back

=head1 METHODS

=over 8

=item B<conf>

    my $value = $ctk->conf("key");

Returns config value by key

See L<CTK::Configuration/"get">

=item B<config>

    my $value = $ctk->config("key");

Returns config value by key

    my $config = $ctk->config();

Returns config-structure as hash-ref

See L<CTK::Configuration/"conf">

=item B<configobj>

    die $ctk->configobj->error unless $ctk->configobj->status;

Returns config-object

=back

=head2 init

Initializer method. Internal use only

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<CTK::Configuration>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::Configuration>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

use CTK::Configuration;

sub init {
    my $self = shift; # It is CTK object!
    my $args = $self->origin;
    my $options = $args->{confopts};

    my $config = new CTK::Configuration(
            config => $self->configfile,
            confdir => $self->root,
            ($options && ref($options) eq 'HASH') ? (options => $options) : (),
        );
    $self->{config} = $config;
    return 1;
}

__PACKAGE__->register_method(
    method    => "configobj",
    callback  => sub { shift->{config} });

__PACKAGE__->register_method(
    method    => "config",
    callback  => sub {
        my $self = shift;
        my $config = $self->{config};
        return $config->conf(@_);
});

__PACKAGE__->register_method(
    method    => "conf",
    callback  => sub {
        my $self = shift;
        my $config = $self->{config};
        return $config->get(@_);
});

1;

__END__
