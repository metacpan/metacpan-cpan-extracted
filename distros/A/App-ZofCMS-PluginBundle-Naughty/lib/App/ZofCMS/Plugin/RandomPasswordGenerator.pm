package App::ZofCMS::Plugin::RandomPasswordGenerator;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use Data::SimplePassword;
use Digest::MD5 (qw/md5_hex/);

sub _key { 'plug_random_password_generator' }
sub _defaults {
    return (
        length   => 8,
        chars    => [ 0..9, 'a'..'z', 'A'..'Z' ],
        cell     => 'd',
        key      => 'random_pass',
        md5_hex  => 0,
        pass_num => 1,
    );
}
sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    my @passwords;

    for ( 1 .. $conf->{pass_num} ) {
        my $sp = Data::SimplePassword->new;
        $sp->chars( @{ $conf->{chars} || [] } );
        my $password = $sp->make_password( $conf->{length} );

        $password = [ $password, md5_hex($password) ]
            if $conf->{md5_hex};

        push @passwords, $password;
    }

    $template->{ $conf->{cell} }{ $conf->{key} }
    = @passwords > 1 ? \@passwords : $passwords[0];
}

1;
__END__

=encoding utf8

=for stopwords subref

=head1 NAME

App::ZofCMS::Plugin::RandomPasswordGenerator - easily generate random passwords with an option to use md5_hex from Digest::MD5 on them

=head1 SYNOPSIS

    # simple usage example; config values are plugin's defaults

    plugins => [ qw/RandomPasswordGenerator/ ],
    plug_random_password_generator => {
        length   => 8,
        chars    => [ 0..9, 'a'..'z', 'A'..'Z' ],
        cell     => 'd',
        key      => 'random_pass',
        md5_hex  => 0,
        pass_num => 1,
    },

    # generated password is now a string in $t->{d}{random_pass}
    # where $t is ZofCMS Template hashref

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to generate one or several
random passwords and optionally use md5_hex() from L<Digest::MD5> on them.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

Make sure to read C<FORMAT OF VALUES FOR GENERATED PASSWORDS> section at the end of this
document.

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/RandomPasswordGenerator/ ],

Self-explanatory: you need to include the plugin in the list of plugins to run.

=head2 C<plug_random_password_generator>

    plug_random_password_generator => {
        length   => 8,
        chars    => [ 0..9, 'a'..'z', 'A'..'Z' ],
        cell     => 'd',
        key      => 'random_pass',
        md5_hex  => 0,
        pass_num => 1,
    },

    plug_random_password_generator => sub {
        my ( $t, $q, $config ) = @_;
        return {
            length   => 8,
            chars    => [ 0..9, 'a'..'z', 'A'..'Z' ],
            cell     => 'd',
            key      => 'random_pass',
            md5_hex  => 0,
            pass_num => 1,
        }
    },

B<Mandatory>. The plugin won't run unless C<plug_random_password_generator> first-level key
is present. Takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_random_password_generator> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object. To run the plugin with all the defaults specify an
empty hashref as a value.
The C<plug_random_password_generator> key can be set in either (or both) Main
Config File and ZofCMS Template;
if set in both, the hashref keys that are set in ZofCMS Template will override the ones that
are set in Main Config File. Possible keys/values of the hashref are as follows:

=head3 C<length>

    plug_random_password_generator => {
        length   => 8,
    }

B<Optional>. Takes a positive integer as a value.
Specifies the length - in characters - of password(s) to generate.
B<Defaults to:> C<8>

=head3 C<chars>

    plug_random_password_generator => {
        chars    => [ 0..9, 'a'..'z', 'A'..'Z' ],
    }

B<Optional>. Takes an I<arrayref> as a value. Elements of this arrayref must be characters;
these characters specify the set of characters to be used in the generated password.
B<Defaults to:> C<[ 0..9, 'a'..'z', 'A'..'Z' ]>

=head3 C<cell>

    plug_random_password_generator => {
        cell     => 'd',
    }

B<Optional>. Takes a string specifying the name of the first-level ZofCMS Template key
into which to create key C<key> (see below) and place the results.
The key must be a hashref (or undef, in which case it will
be autovivified); why? see C<key> argument below.
B<Defaults to:> C<d>

=head3 C<key>

    plug_random_password_generator => {
        key      => 'random_pass',
    }

B<Optional>. Takes a string specifying the name of the ZofCMS Template key in hashref
specified be C<cell> (see above) into which to place the results. In other words, if C<cell>
is set to C<d> and C<key> is set to C<random_pass> then generated password(s) will be found
in C<< $t->{d}{random_pass} >> where C<$t> is ZofCMS Template hashref.
B<Defaults to:> C<random_pass>

=head3 C<md5_hex>

    plug_random_password_generator => {
        md5_hex  => 0,
    }

B<Optional>. Takes either true or false values. When set to a true value, the plugin will
also generate string that is made from calling C<md5_hex()> from L<Digest::MD5> on the
generated password. See C<FORMAT OF VALUES FOR GENERATED PASSWORDS> section below.
B<Defaults to:> C<0>

=head3 C<pass_num>

    plug_random_password_generator => {
        pass_num => 1,
    }

B<Optional>. Takes a positive integer as a value. Specifies the number of passwords to
generate. See C<FORMAT OF VALUES FOR GENERATED PASSWORDS> section below.
B<Defaults to:> C<1>

=head1 FORMAT OF VALUES FOR GENERATED PASSWORDS

Examples below assume that C<cell> argument is set to C<d> and C<key> argument is set
to C<random_pass> (those are their defaults). The C<$VAR> is ZofCMS Template hashref, other
keys of this hashref were removed for brevity.

    # all defaults
    $VAR1 = {
        'd' => {
            'random_pass' => 'ETKSeRJS',
    ...

    # md5_hex option is set to a true value, the rest are defaults
    $VAR1 = {
        'd' => {
            'random_pass' => [
                                '3b6SY9LY',                         # generated password
                                '6e28112de1ff183966248d78a4aa1d7b'  # md5_hex() ran on it
                             ]
    ...

    # pass_num is set to 2, the rest are defaults
    $VAR1 = {
        'd' => {
            'random_pass' => [
                                'oqdQmwZ5', # first password
                                'NwzRv6q8'  # second password
                             ],
    ...

    # pass_num is set to 2 and md5_hex is set to a true value
    $VAR1 = {
        'd' => {
            'random_pass' => [
                [
                    '9itPzasC',                             # first password
                    '5f29eb2cf6dbccc048faa9666187ac22'      # md5_hex() ran on it
                ],
                [
                    'ytRRXqtq',                            # second password
                    '81a6a7836e1d08ea2ae1c43c9dbef941'     # md5_hex() ran on it
                ]
            ]
    ...

There are B<four different types> of values (depending on settings) that plugin will generate.
B<In the following text, word "output value" will be used to refer to the value of the key
referred to by> C<key> and C<cell> plugin's arguments; in other words, if C<cell> is
set to C<d> and C<key> is set to C<random_pass> then "output value" will be the value of
C<< $t->{d}{random_pass} >> where C<$t> is ZofCMS Template hashref.

With all the defaults output value will be a single string that is the generated password.

If C<md5_hex> option is set to a true value, instead of that string the plugin will generate
an I<arrayref> first element of which will be the generated password and second element will
be the string generated by running C<md5_hex()> on that password.

If C<pass_num> is set to a number greater than 1 then each generated password will be an
element of an arrayref instead and output value will be an arrayref.

See four examples in the beginning of this section if you are still confused.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS-PluginBundle-Naughty at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut