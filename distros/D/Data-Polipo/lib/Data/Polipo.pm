package Data::Polipo;

use 5.008009;
use strict;
use warnings;

use IO::File;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Polipo ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

our $count = 0;

sub new {
    my ($class, $file) = @_;
    my $h = {};

    my $fh = new IO::File $file, "r" or die "$file: $!";
    $fh->binmode;
    local $/ = "\r\n";
    my $res = <$fh>;
    chomp $res;

    my $ns = $class . "::" . $count ++;

    while (my $line = <$fh>) {
	chomp $line;
	last if ($line =~ /^$/);

	my ($k, $v) = $line =~ /([^:]+):\s*(.*)/;
	warn $line and next unless ($k);
	$k =~ s/-/_/g;
	$k =~ s/^(.+)$/\L$1\E/;
	if (! defined $h->{$k}) {
	    $h->{$k} = $v;
	    no strict 'refs';
	    *{$ns . "::" . $k} = (sub {my $v=shift; sub {$v}})->($v);
	}
    }

    if (my $offset = $h->{x_polipo_body_offset}) {
	$fh->seek ($offset, SEEK_SET);
    }

    my $d = bless {} => $ns;
    my $obj = sub {wantarray ? ($fh, $res) : $d};
    bless $obj => $class;
}

sub open {
    return ($_[0]->())[0];
}

sub status {
    return ($_[0]->())[1];
}

sub header {
    return $_[0]->();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Data::Polipo - Perl extension for Polipo cache files

=head1 SYNOPSIS

  use Data::Polipo;
  
  my $p = new Data::Polipo ("o3kvmCJ-O2CcW2TH2KebbA==");
  
  $p->status;			# HTTP status
  $p->header->content_type;	# Content-Type
  $p->header->x_polipo_location; # Polipo-specific header
  
  my $fh = $p->open;		# Get file handle to read content
  my $content = <$fh>;		# Read data from cache file

=head1 DESCRIPTION

Data::Polipo is a module which allows you to get HTTP header and
content data from Polipo's cache file.

=head2 EXPORT

None by default.

=head2 METHODS

=over 4

=item new Data::Polipo (FILENAME)

Open a cache file and returns a Data::Polipo object.

=item $p->status

Returns the HTTP return status (like "HTTP/1.1 200 OK").

=item $p->open

Returns an IO::File object to read the content data.

=back

=head2 HTTP HEADER

 $p->header->field_name

returns header value of "Field-Name".  field_name must be lower-cased
and replaced "-" with "_".  E.g. to get Content-Type header value,
call like this:

 $p->header->content_type

=head1 SEE ALSO

Polipo L<http://www.pps.jussieu.fr/~jch/software/polipo/>,
IO::File

=head1 AUTHOR

Toru Hisai, E<lt>toru@torus.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Toru Hisai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
