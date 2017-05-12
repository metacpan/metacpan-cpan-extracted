package Apache2::Protocol;

=head1 DESCRIPTION

Apache2::Protocol - 

=cut


use strict;
#use warnings FATAL => 'all';

use Apache2::TieBucketBrigade;
use Apache2::Const;
use base qw/Class::Accessor/;

our $VERSION = 0.1;

__PACKAGE__->mk_accessors(qw/default_line_handler
			     chunkhandler
			     connecthandler
			     disconnecthandler
			     input_handle
			     output_handle
			     regexdispatch
			     chunkmode
			     chunksize
			     disconnect
			     /);
			     

sub handler {
    my $c = shift;
    my $self = shift || Apache2::Protocol->new;

    my $ath = Apache2::TieBucketBrigade->new_tie($c);
    $self->input_handle($ath);
    $self->output_handle($ath);
    
    my %qrdispatch = %{$self->regexdispatch};
    $self->connecthandler->($self);

NOTCHUNK:
    if (!$self->chunkmode) {
	$ath->blocking(1);
	my $matched = 0;
        while (my $line = <$ath>) {
	    while(my ($tag, $enabled) = each %{$self->{enabled_tags}}) {
		if($enabled) {
		    while(my ($qr, $cb) = each %{$qrdispatch{$tag}}) {
			if($line =~ $qr) {
			    $matched = 1;
			    my @matches = ();
			    for(my $i = 1; $i < @-; $i++) {
			    	push(@matches, substr($line, $-[$i], $+[$i] - $-[$i]));	
			    }
			    $cb->($self, @matches);
			}
		    }
		}
	    }

	    unless($matched) {
		$self->default_line_handler->($self, $line);
	    }
	    $matched = 0;
            goto DISCONNECT if $self->disconnect;
            goto CHUNK if $self->chunkmode;
        }
    }

CHUNK: 
    while ($self->chunkmode) {
	$ath->blocking(0);
	my $chunk;
	my $nbytes = read($ath, $chunk, $self->chunksize);
	if($nbytes > 0) {
	    $self->chunkhandler->($self, $chunk);
	}
	else {
	    my $rc = $c->client_socket->poll($c->pool, 1_000_000 * 100, APR::Const::POLLIN);
	    if($rc == APR::Const::SUCCESS) {
		next;
	    }
	    elsif ($rc == APR::Const::TIMEUP) {
		print STDERR "Timeout polling\n";
		$self->disconnect(1);
	    }
	    else {
		die "poll error: " . APR::Error::strerror($rc);
	    }
	}

	goto DISCONNECT if $self->disconnect;
	goto NOTCHUNK unless $self->chunkmode;
    }

    DISCONNECT:  $self->disconnecthandler->($self);
    return Apache2::Const::OK;
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    $self->regexdispatch({});
    $self->chunkmode(0);
    $self->disconnect(0);
    $self->chunksize(1024);
    $self->disconnecthandler(sub{ close(shift->input_handle) });
    $self->connecthandler(sub{});
    $self->default_line_handler(sub{});
    $self->chunkhandler(sub{});
    return $self;
}

sub register_callback {
    my $self  = shift;
    my $regex = shift;
    my $cb    = shift;
    my $tag   = shift  || 'DEFAULT';

    $self->{regexdispatch}{$tag}{$regex} = $cb;
    unless(exists $self->{enabled_tags}{$tag}) {
	$self->enable_callbacks($tag);
    }
}

sub enable_callbacks {
    my $self = shift;
    my $tag  = shift || 'DEFAULT';
    $self->{enabled_tags}{$tag} = 1;
}

sub disable_callbacks {
    my $self = shift;
    my $tag  = shift || 'DEFAULT';
    $self->{enabled_tags}{$tag} = 0;
}

=head1 SEE ALSO

Apache2::Const
Apache2::TieBucketBrigade
Class::Accessor

=head1 AUTHOR

Will Whittaker <will@mailchannels.com>
Mike Smith <mike@mailchannels.com>

=head1 COPYRIGHT

Copyright (C) 2005 by MailChannels Corporation.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
