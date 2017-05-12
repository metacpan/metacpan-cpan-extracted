#
# (C) 2015, Snehasis Sinha
#
package Apache::Hadoop::Watcher::Base;

use 5.010001;
use strict;
use warnings;

use IO::Socket::INET;
use LWP::UserAgent;
use Data::Dumper;

our @ISA = qw();
our $VERSION = '0.01';


# base methods
sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = { };
    bless $self, $class;
    return $self;
}

# common methods
sub _wget {
    my ($self, %opts) = (@_);
    my $content;
    my $res;
    my $ua;

    $ua  = LWP::UserAgent->new;
    $res = $ua->get ( $opts{'url'} );
    return 'error' unless $res->is_success;

    $content = $res->decoded_content;
    return $content;
}

sub _port {
    my (%opts) = (@_);
    my $socket = IO::Socket::INET->new(
        Proto=>'tcp',
        PeerAddr=>$opts{'host'} || '0.0.0.0',
        PeerPort=>$opts{'port'} || 0
        ) || undef;
    return (defined $socket ? 1 : undef);
}

# changing json boolean object to perl values
sub _jsontr {
    my ($self, $hash) = (@_);
    foreach my $v ( values %{$hash} ) {
        $v = ($v ? 'true' : 'false') if ref $v eq 'JSON::PP::Boolean';
        $self->_jsontr ( $v ) if ref $v eq 'HASH';
    }
    #return $hash;
}

sub _jsonjmx {
	my ($self, $hook) = (@_);
	if ( ref $hook eq 'HASH' ) {
		$self->_jsontr ( $hook );
	}
	if ( ref $hook eq 'ARRAY' ) {
		foreach my $e ( @$hook ) {
			$self->_jsontr ( $e );
		}
	}
}

# dumps output hashref
sub _print {
    my ($self, %opts) = (@_);
    print Dumper ( $opts{'output'} );
}

1;

__END__

=head1 NAME

Apache::Hadoop::Watcher::Base - Base package for Hadoop Watchers

=head1 SYNOPSIS

  use Apache::Hadoop::Watcher::Base;
  
  my $w = Apache::Hadoop::Watcher::Base->new;
  my $content = $w->_wget (url=>$url);
  $w->_print (output=>$output);


=head1 DESCRIPTION

Apache::Hadoop::Watcher::Base is a supportive package containing
common subroutines used by other packages, in the Apache::Hadoop::Watcher
package group.


=head1 SEE ALSO

  Apache::Hadoop::Watcher::Conf
  Apache::Hadoop::Watcher::Jmx
  Apache::Hadoop::Watcher::Yarn
  Apache::Hadoop::Watcher
  IO::Socket::INET;
  LWP::UserAgent;
  Data::Dumper;


=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
