package Config::Any::TT2;

use strict;
use warnings;

use base 'Config::Any::Base';

our $VERSION = '0.12';

=head1 NAME

Config::Any::TT2 - Config::Any plugin for Config::TT2 files

=head1 SYNOPSIS

    use Config::Any;

    my $cfg_file = 'cfg.tt2';

    my $configs = Config::Any->load_files(
        {
            files           => [$cfg_file],
            flatten_to_hash => 1,
            use_ext         => 1,
        }
    );

    my $cfg = $configs->{$cfg_file};

=head1 DESCRIPTION

Loads Config::TT2 files. Example:

  [%                        # tt2 directive start-tag
    scalar = 'string'

    array = [ 10 20 30 ]    # commas are optional
    rev   = array.reverse   # powerful virtual methods
    item  = array.0         # interpolate previous value

    hash = { foo = 'bar'    # hashes to any depth
             moo = array    # points to above arrayref
	   }
  %]                        # tt2 directive end-tag

=head1 METHODS

=head2 extensions( )

return an array of valid extensions (C<tt2>, C<tt>).

=cut

sub extensions {
    return qw( tt2 tt );
}

=head2 load( $file )

Attempts to load C<$file> via Config::TT2.

=cut

sub load {
    my $class = shift;
    my $file  = shift;
    my $args  = shift || {};

    require Config::TT2;
    my $cfg = Config::TT2->new( $args )->process( $file );

    return $cfg;

    # maybe we need instead a shallow, unblessed copy for Config::Any
    # return { %$cfg };
}

=head2 requires_all_of( )

Specifies that this module requires L<Config::TT2> in order to work.

=cut

sub requires_all_of { [ 'Config::TT2' ] }

=head1 AUTHOR

Karl Gaissmaier E<lt>gaissmai@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Karl Gaissmaier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Config::Any>

=item * L<Config::TT2>

=back

=cut

1;
