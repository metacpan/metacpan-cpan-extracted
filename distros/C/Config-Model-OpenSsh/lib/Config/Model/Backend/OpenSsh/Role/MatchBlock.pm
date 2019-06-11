#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Role::MatchBlock v2.7.9.1;

use Mouse::Role ;

requires qw(current_node write_node_content write_line);

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

sub match {
    my ($self, $root, $key, $pairs, $comment, $check) = @_ ;
    $logger->debug("match: @$pairs # $comment");
    my $list_obj = $root->fetch_element('Match');

    # create new match block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;
    $block_obj->annotation($comment) ;

    while (@$pairs) {
        my $criteria = shift @$pairs;
        my $pattern  = shift @$pairs;
        $block_obj->load(
            steps => qq!Condition $criteria="$pattern"!,
            check => $check,
        );
    }

    $self->current_node( $block_obj->fetch_element('Settings') );
}


sub write_all_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $result = '';
    foreach my $elt ($match_elt->fetch_all($mode) ) {
        $result .= $self->write_match_block($elt,$mode) ;
    }

    return $result ;
}

sub write_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $match_line ;
    my $match_body ;

    foreach my $name ($match_elt->get_element_name() ) {
        my $elt = $match_elt->fetch_element($name) ;

        if ($name eq 'Settings') {
            $match_body .= $self->write_node_content($elt,$mode)."\n" ;
        }
        elsif ($name eq 'Condition') {
            $match_line = $self->write_line(
                Match => $self->write_match_condition($elt,$mode) ,
                $match_elt -> annotation
            ) ;
        }
        else {
            die "write_match_block: unexpected element: $name";
        }
    }

    return $match_line.$match_body ;
}

sub write_match_condition {
    my $self = shift ;
    my $cond_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $name ($cond_elt->get_element_name() ) {
        my $elt = $cond_elt->fetch_element($name) ;
        my $v = $elt->fetch($mode) ;
        $result .= " $name $v" if defined $v;
    }

    return $result ;
}

no Mouse;

1;

# ABSTRACT: Backend role for Ssh Match blocks

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Role::MatchBlock - Backend role for Ssh Match blocks

=head1 VERSION

version v2.7.9.1

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This class provides a backend role to read and write C<Match> blocks
in OpenSsh configuration files.

=head1 SEE ALSO

L<Config::Model::Backend::OpenSsh>,

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2019 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
