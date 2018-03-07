package CGI::Application::Plugin::Authentication::Driver;
$CGI::Application::Plugin::Authentication::Driver::VERSION = '0.23';
use strict;
use warnings;

use UNIVERSAL::require;

=head1 NAME

CGI::Application::Plugin::Authentication::Driver - Base module for building driver classes
for CGI::Application::Plugin::Authentication

=head1 SYNOPSIS

 package CGI::Application::Plugin::Authentication::Driver::MyDriver;
 use base qw(CGI::Application::Plugin::Authentication::Driver);

  sub verify_credentials {
      my $self = shift;
      my @credentials = @_;

      if ( >>> Validate Credentials <<< ) {
          return $credentials[0];
      }
      return;
  }


=head1 DESCRIPTION

This module is a base class for all driver classes for the L<CGI::Application::Plugin::Authentication>
plugin.  Each driver class is required to provide only one method to validate the given credentials.
Normally only two credentials will be passed in (username and password), but you can configure the plugin
to handle any number of credentials (for example you may require the user to enter a group name, or domain name
as well as a username and password).


=head1 FIELD FILTERS

It is quite common for passwords to be stored using some form of one way encryption.  Unix crypt being the
old standard in the Unix community, however MD5 or SHA1 hashes are more popular today.  In order to
simplify the validation routines some methods have been provided to help test these passwords.  When
configuring a Driver (and if the driver supports it), you can specify which fields are encoded, and which
method is used for the encoding by specifying a filter on the field in question.

 CREDENTIALS => ['authen_username', 'authen_password'],
 DRIVERS     => [ 'DBI',
                    DSN         => '...',
                    TABLE       => 'users',
                    CONSTRAINTS => {
                        username       => '__CREDENTIAL_1__',
                        'MD5:password' => '__CREDENTIAL_2__',
                    }
                ],

Here we are saying that the password field is encoded using an MD5 hash, and should be checked accordingly.

=head2 Filter options

Some of the filters may have multiple forms.  For example there are three forms of MD5 hashes:  binary, base64 and hex.
You can specify these extra options by using an underscore to separate it from the filter name.

 'MD5_base64:password'


=head2 Chained Filters

it is possible to chain multiple filters.  This can be useful if your MD5 strings are stored in hex format.  Hex numbers are
case insensitive, so the may be stored in either upper or lower case.  To make this consistent, you can MD5 encode the
password first, and then upper case the results.  The filters are applied from the inside out:

 'uc:MD5_hex:password'

=head2 Custom Filters

If your field is encoded using a custom technique, then you can provide a custom filter function.  This can be
be done by providing a FILTERS option that contains a hash of filter subroutines that are keyed by their name.
You can then use the filter name on any of the fields as if it was a builtin filter.

 CREDENTIALS => ['authen_username', 'authen_password'],
 DRIVERS     => [ 'DBI', 
                    DSN      => '...',
                    TABLE    => 'users',
                    CONSTRAINTS => {
                        username         => '__CREDENTIAL_1__',
                        'rot13:password' => '__CREDENTIAL_2__',
                    }
                    FILTERS => { rot13 => \&rot13_filter },
                ],

 sub rot13_filter {
     my $param = shift;
     my $value = shift;
     $value =~ tr/A-Za-z/N-ZA-Mn-za-m/;
     return $value;
 }

Please see the documentation for the driver that you are using to make sure that it supports encoded
fields.


=head2 Builtin Filters

Here is a list of the filters that are provided with this module:

=over 4

=item crypt - provided by perl C<crypt> function

=item MD5 - requires Digest::MD5

=item SHA1 - requires Digest::SHA1

=item uc - provided by the perl C<uc> function

=item lc - provided by the perl C<lc> function

=item trim - removed whitespace from the start and end of the field

=back


=head1 METHODS

=head2 new

This is a constructor that can create a new Driver object.  It requires an Authentication object as its
first parameter, and any number of other parameters that will be used as options depending on which
Driver object is being created.  You shouldn't need to call this as the Authentication plugin takes care
of creating Driver objects.

=cut

sub new {
    my $class = shift;
    my $self = {};
    my $authen = shift;
    my @options = @_;

    bless $self, $class;
    $self->{authen} = $authen;
    Scalar::Util::weaken($self->{authen}); # weaken circular reference
    $self->{options} = \@options;
    $self->initialize;
    return $self;
}

=head2 initialize

This method will be called right after a new Driver object is created.  So any startup customizations
can be dealt with here.

=cut

sub initialize {
    my $self = shift;
    # override this in the subclass if you need it
    return;
}

=head2 options

This will return a list of options that were provided when this driver was configured by the user.

=cut

sub options { return (@{$_[0]->{options}}) }

=head2 authen

This will return the underlying L<CGI::Application::Plugin::Authentication> object.  In most cases it will
not be necessary to access this.

=cut

sub authen { return $_[0]->{authen} }

=head2 find_option

This method will search the Driver options for a specific key and return
the value it finds.

=cut

sub find_option {
    my $self = shift;
    my $key = shift;
    my @options = $self->options;
    my $marker = 0;
    foreach my $option (@options) {
        if ($marker) {
            return $option;
        } elsif ($option eq $key) {
            # We need the next element
            $marker = 1;
        }
    }
    return;
}

=head2 verify_credentials

This method needs to be provided by the driver class.  It needs to be an object method that accepts a list of
credentials, and will verify that the credentials are valid, and return a username that will be used to identify
this login (usually you will just return the value of the first credential, however you are not bound to that)..

=cut

sub verify_credentials {
    die "verify_credentials must be implemented in the subclass";
}

=head2 filter

This method can be used to filter a field (usually password fields) using a number of standard or
custom encoding techniques.  See the section on Builtin Filters above to see what filters are available
When using a custom filter, you will need to provide a FILTERS option in the configuration of the DRIVER (See the
section on FIELD FILTERS above for an example).  By default, if no filter is specified, it is
returned as is.  This means that you can run all fields through this function even if they
don't have any filters to simplify the driver code.

 my $filtered = $self->filter('MD5_hex:password', 'foobar');

 - or -

 # custom filter
 my $filtered = $self->filter('foobar:password', 'foo');

 - or -

 # effectively a noop
 my $filtered = $self->filter('username', 'foo');



=cut

sub filter {
    my $self  = shift;
    my $field = shift;
    my $plain = shift;
    my @other = shift;

    return unless defined $plain;

    my @filters = split /\:/, $field;
    my $fieldname = pop @filters;

    my $filtered = $plain;
    foreach my $filter (reverse @filters) {

        my ($filter_name, $param) = split /_/, $filter;
        my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::' . lc $filter_name;
        if ( $class->require ) {
            # found a filter
            $filtered = $class->filter( $param, $filtered, @other );
        } else {
            # see if the configuration has a custom filter defined
            my $custom_filters = $self->find_option('FILTERS');
            if ( $custom_filters ) {
                die "the FILTERS configuration option must be a hashref"
                  unless ref( $custom_filters ) eq 'HASH';
                if ( $custom_filters->{$filter_name} ) {
                    die "the '$filter' filter listed in FILTERS must be a subroutine reference"
                      unless ref( $custom_filters->{$filter_name} ) eq 'CODE';
                    $filtered = $custom_filters->{$filter_name}->( $param, $filtered, @other );
                } else {
                    die "No filter found for '$filter_name'";
                }
            } else {
                die "No filters found for '$filter'";
            }
        }
    }
    return $filtered;
}

=head2 check_filtered

This method can be used to test filtered fields (usually password fields) against a number of standard or
custom encoding techniques.  The following encoding techniques are provided:  plain, MD5, SHA1, crypt.
When using a custom encoder, you will need to provide it in the configuration of the DRIVERS (See the
section on ENCODED PASSWORDS above for an example).  By default, if no encoding is specified, it is
assumed to be 'plain'.  This means that you can run all fields through this function even if they
don't have any encoding to simplify the driver code.

 my $verified = $self->check_filtered('MD5:password', 'foobar', 'OFj2IjCsPJFfMAxmQxLGPw');

 - or -

 # custom encoder
 my $verified = $self->check_filtered('foobar:password', 'foo', 'bar');

 - or -

 # a field that isn't filtered (effectively just checks for equality on second and third args)
 my $verified = $self->check_filtered('username', 'foobar', 'foobar');
 my $verified = $self->check_filtered('plain:username', 'foobar', 'foobar');

=cut

sub check_filtered {
    my $self    = shift;
    my $field   = shift;
    my $plain   = shift;
    my $filtered = shift;

    return ($self->filter($field, $plain, $filtered) eq $filtered) ? 1 : 0;
}

=head2 strip_field_names

This method will take a field name (or list of names) and strip off the leading encoding type.
For example if you passed in 'MD5:password' the method would return 'password'.

 my $fieldname = $self->strip_field_names('MD5:password');

=cut

sub strip_field_names {
    my $self   = shift;
    my @fields = @_;

    foreach (@fields) {
        s/^.*://;
    }
    if (wantarray()) {
        return @fields;
    } else {
        return $fields[0];
    }
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
