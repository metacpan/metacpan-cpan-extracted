#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Role::Reader v2.7.9.1;

use 5.10.1;

use Config::Model 2.128;

use Mouse::Role ;
requires qw(read_global_comments associates_comments_with_data);

# sub stub known as "forward" declaration
# required for Role consistency checks
# See Moose::Manual::Roles for details
sub current_node;

has 'current_node'  => (
    is => 'rw',
    isa => 'Config::Model::Node',
    weak_ref => 1
) ;

use Carp ;
use Log::Log4perl 1.11;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

my @dispatch = (
    qr/match/i                 => 'match',
    qr/host\b/i                => 'host',
    qr/(local|remote)forward/i => 'forward',
    qr/^PreferredAuthentications$/ => 'comma_list',
    qr/localcommand/i          => 'assign',
    qr/\w/                     => 'assign',
);

sub read {
    my $self = shift ;
    my %args = @_ ;
    my $config_root = $args{object}
        || croak __PACKAGE__," read_ssh_file: undefined config root object";

    $logger->info("loading config file ".$args{file_path});

    my @lines = $args{file_path}->lines_utf8 ;
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
    return 1;
}

sub comma_list {
    my ($self,$root, $raw_key,$arg,$comment, $check) = @_ ;
    $logger->debug("assign: $raw_key @$arg # $comment");

    my @list = map { split /\s*,\s*/ } @$arg;
    $self->assign($root, $raw_key,\@list,$comment, $check);
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

    if ($type eq 'leaf') {
        $elt->store( value => join(' ',@$arg), check => $check ) ;
    }
    elsif ($type eq 'list') {
        $elt->push_x ( values => $arg, check => $check ) ;
    }
    elsif ($type eq 'hash') {
        my $hv = $elt->fetch_with_id($arg->[0]);
        $hv->store( value => $arg->[1], check => $check );
        $hv->annotation($comment) if $comment;
    }
    elsif ($type eq 'check_list') {
        my @check = split /\s*,\s*/,$arg->[0] ;
        $elt->set_checked_list (\@check, check => 'skip') ;
    }
    else {
        die "OpenSsh::assign did not expect $type for $key\n";
    }
}

no Mouse;

1;

# ABSTRACT: Role to read OpenSsh config files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Role::Reader - Role to read OpenSsh config files

=head1 VERSION

version v2.7.9.1

=head1 SYNOPSIS

None. Consumed by L<Config::Model::Backend::OpenSsh::Ssh> and
L<Config::Model::Backend::OpenSsh::Sshd>.

=head1 DESCRIPTION

Read methods used by both L<Config::Model::Backend::OpenSsh::Ssh> and
L<Config::Model::Backend::OpenSsh::Sshd>.

=head1 SEE ALSO

L<cme>, L<Config::Model>, L<Config::Model::OpenSsh>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2019 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
