#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh ;
$Config::Model::Backend::OpenSsh::VERSION = '1.238';
use 5.10.1;

use Config::Model 2.050;

use Mouse ;
extends "Config::Model::Backend::Any" ;

has 'current_node'  => ( 
    is => 'rw', 
    isa => 'Config::Model::Node',
    weak_ref => 1 
) ;


use Carp ;
use IO::File ;
use Log::Log4perl 1.11;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

my @dispatch = (
    qr/match/i                 => 'match',
    qr/host\b/i                => 'host',
    qr/(local|remote)forward/i => 'forward',
    qr/localcommand/i          => 'assign',
    qr/\w/                     => 'assign',
);

sub suffix {return '';}

sub read {
    my $self = shift ;
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read_ssh_file: undefined config root object";

    $logger->info("loading config file ".$args{file_path});

    my $fh = $args{io_handle} ;
    if (not defined $fh) {
        $logger->warn("cannot read $args{file_path}");
        return 0;
    }

    my @lines = $fh->getlines ;
    # try to get global comments (comments before a blank line)
    $self->read_global_comments(\@lines,'#') ;

    # need to reset this when reading user ssh file after system ssh file
    $self->current_node($config_root) ;

    my @assoc = $self->associates_comments_with_data( \@lines, '#' ) ;
    foreach my $item (@assoc) {
        my ( $vdata, $comment ) = @$item;

        my ( $k, @v ) = split /\s+/, $vdata;

        my $i = 0;
        while ( $i < @dispatch ) {
            my ( $regexp, $sub ) = @dispatch[ $i++, $i++ ];
            if ( $k =~ $regexp and $self->can($sub)) {
                $logger->trace("read_ssh_file: dispatch calls $sub");
                $self->$sub( $config_root, $k, \@v, $comment, $args{check} );
                last;
            }

            warn __PACKAGE__, " unknown keyword: $k" if $i >= @dispatch;
        }
    }
    $fh->close;
    return 1;
}

sub ssh_write {
    my $self = shift ;
    my %args = @_ ;

    my $config_root = $args{object}
      || croak __PACKAGE__," ssh_write: undefined config root object";

    $logger->info("writing config file $args{file_path}");

    my $ioh = $args{io_handle} || croak __PACKAGE__," ssh_write: undefined io_handle";;
    $self->write_global_comment($ioh,'#') ;

    my $result = $self->write_node_content($config_root,$args{ssh_mode});

    $ioh->print ($result);

    return 1;
}

sub assign {
    my ($self,$root, $raw_key,$arg,$comment, $check) = @_ ;
    $logger->debug("assign: $raw_key @$arg # $comment");


    # keys are case insensitive, try to find a match
    my $key = $self->current_node->find_element ($raw_key, case => 'any') ;

    if (not defined $key) {
        if ($check eq 'yes') {
            # drop if -force is not set
            die "Error: unknown parameter: '$raw_key'. Use -force option to drop this parameter\n";
        }
        else {
            say "Dropping parameter '$raw_key'" ;
        }
        return;
    }

    my $elt = $self->current_node->fetch_element($key) ;
    my $type = $elt->get_type;
    #print "got $key type $type and ",join('+',@$arg),"\n";

    $elt->annotation($comment) if $comment and $type ne 'hash';
    
    if    ($type eq 'leaf') { 
	$elt->store( join(' ',@$arg) ) ;
    }
    elsif ($type eq 'list') { 
	$elt->push ( @$arg ) ;
    }
    elsif ($type eq 'hash') {
        my $hv = $elt->fetch_with_id($arg->[0]);
        $hv->store( $arg->[1] );
        $hv->annotation($comment) if $comment;
    }
    elsif ($type eq 'check_list') {
	my @check = split /,/,$arg->[0] ;
        $elt->set_checked_list (@check) ;
    }
    else {
       die "OpenSsh::assign did not expect $type for $key\n";
    }
  }


sub write_line {
    my ($self, $k, $v, $note) = @_ ;
    return '' unless length($v) ;
    return $self->write_data_and_comments( undef, '#',sprintf("%-20s %s",$k,$v),$note) ;
}

sub write_list {
    my ($self,$name,$mode,$elt) = @_;
    my @r = map { $self->write_line($name,$_->fetch($mode), $_->annotation) ;} $elt->fetch_all() ;
    return join('',@r) ;
}


sub write_list_in_one_line {
    my ($self,$name,$mode,$elt) = @_;
    my @v = $elt->fetch_all_values(mode => $mode) ;
    return $self->write_line($name,join(' ',@v)) ;    
}

# list there list element that must be written on one line with items
# separated by a white space
my %list_as_one_line = (
    'AuthorizedKeysFile' => 1 ,
) ;

sub write_node_content {
    my $self= shift ;
    my $node = shift ;
    my $mode = shift || '';

    my $result = '' ;
    my $match  = '' ;

    foreach my $name ($node->get_element_name() ) {
	next unless $node->is_element_defined($name) ;
	my $elt = $node->fetch_element($name) ;
	my $type = $elt->get_type;
	my $note = $elt->annotation ;

	#print "got $key type $type and ",join('+',@arg),"\n";
	if    ($name eq 'Match') { 
	    $match .= $self->write_all_match_block($elt,$mode) ;
	}
	elsif    ($name eq 'Host') { 
	    $match .= $self->write_all_host_block($elt,$mode) ;
	}
	elsif    ($name =~ /^(Local|Remote)Forward$/) { 
	    map { $result .= $self->write_forward($_,$mode) ;} $elt->fetch_all() ;
	}
	elsif    ($type eq 'leaf') { 
	    my $v = $elt->fetch($mode) ;
	    if (defined $v and $elt->value_type eq 'boolean') {
		$v = $v == 1 ? 'yes':'no' ;
	    }
	    $result .= $self->write_line($name,$v,$note);
	}
	elsif    ($type eq 'check_list') { 
	    my $v = $elt->fetch($mode) ;
	    $result .= $self->write_line($name,$v,$note);
	}
	elsif ($type eq 'list') { 
	    $result .= $self->write_data_and_comments(undef,'#', undef, $note) ; 
	    $result .= $list_as_one_line{$name} ? $self->write_list_in_one_line($name,$mode,$elt)
                    :                             $self->write_list($name,$mode,$elt) ;
	}
	elsif ($type eq 'hash') {
	    foreach my $k ( $elt->fetch_all_indexes ) {
		my $o = $elt->fetch_with_id($k);
		my $v = $o->fetch($mode) ;
		$result .=  $self->write_line($name,"$k $v", $o->annotation) ;
	    }
	}
	else {
	    die "OpenSsh::write did not expect $type for $name\n";
	}
    }

    return $result.$match ;
}

no Mouse;

1;

# ABSTRACT: Common backend methods for Ssh and Sshd backends

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh - Common backend methods for Ssh and Sshd backends

=head1 VERSION

version 1.238

=head1 SYNOPSIS

None. Inherited by L<Config::Model::Backend::OpenSsh::Ssh> and
L<Config::Model::Backend::OpenSsh::Sshd>. 

=head1 DESCRIPTION

Methods used by both L<Config::Model::Backend::OpenSsh::Ssh> and
L<Config::Model::Backend::OpenSsh::Sshd>. 

=head1 SEE ALSO

L<cme>, L<Config::Model>, L<Config::Model::OpenSsh>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2014 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
