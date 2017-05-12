package Config::Format::Ini;

use 5.008008;
use strict;
use warnings;

use base qw( Exporter );
our @EXPORT = qw( read_ini  );
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.07';

use Config::Format::Ini::Grammar;
use File::Slurp qw(slurp);

our $SIMPLIFY=0;

sub read_ini {
	return unless @_;
	my $msg;
        $msg  .= scalar slurp $_  for @_ ;
	my $p  = new Config::Format::Ini::Grammar;
	my $result = $p->startrule( $msg );
	_simplify( $result)  if $SIMPLIFY;
	$result;
}

sub _arr2scalar {
        # change arrays with one element to string
        my $ref = shift ||return;
        return unless ref $ref eq 'HASH';
        while (my( $k,$v )=each %$ref) {
                next unless ref $v eq 'ARRAY';
                (1 == @$v ) and $ref->{$k} = $v->[0];
                (0 == @$v ) and $ref->{$k} = undef;
        }
}
sub _simplify {
        my $ini =shift;
        return unless ref $ini eq 'HASH';
        (0 == keys %{$ini->{$_}})
                ? undef $ini->{$_}
                : _arr2scalar  $ini->{$_}
                for (keys %$ini);
}


1;
__END__

=head1 NAME

Config::Format::Ini - Reads INI configuration files

=head1 SYNOPSIS

  use Config::Format::Ini;

=head1 DESCRIPTION

This module reads INI files by following the spec
presently found at http://www.cloanto.com/specs/ini.html .
It supports most of the spec, including multi-valued keys (separated by
commas), double-quoted values, and free comments, and overide of earlier
sections and keys.

Escape and continuation strings are in the TODO list.

=head2 EXPORT

=over

=item read_ini() 
Reads ini data from filename, or filenames when multiple 
arguments are supplied.


=back


=head1 SEE ALSO

Config::Ini, Config::INI::Simple, Config::IniFiles, and
OpenInteract2::Config::Ini .  There is a paper about the INI format
at http://www.cloanto.com/specs/ini.html .

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
