#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Role::Writer v2.7.9.1;

use Mouse::Role ;

with 'Config::Model::Backend::OpenSsh::Role::MatchBlock';

requires qw(write_global_comments write_data_and_comments);

use 5.10.1;

use Config::Model 2.128;

use Carp ;
use IO::File ;
use Log::Log4perl 1.11;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

sub ssh_write {
    my $self = shift ;
    my %args = @_ ;

    my $config_root = $args{object}
        || croak __PACKAGE__," ssh_write: undefined config root object";

    $logger->info("writing config file $args{file_path}");

    my $result = $self->write_global_comment('#') ;

    $result .= $self->write_node_content($config_root,$args{ssh_mode});

    $args{file_path}->spew_utf8($result);

    return 1;
}


sub write_line {
    my ($self, $k, $v, $note) = @_ ;
    return '' unless length($v) ;
    return $self->write_data_and_comments('#',sprintf("%-20s %s",$k,$v),$note) ;
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
        if ($name eq 'Match') {
            $match .= $self->write_all_match_block($elt,$mode) ;
        }
        elsif ($name eq 'Host') {
            $match .= $self->write_all_host_block($elt,$mode) ;
        }
        elsif ($name =~ /^(Local|Remote)Forward$/) {
            foreach ($elt->fetch_all()) {
                $result .= $self->write_forward($_,$mode);
            }
        }
        elsif ($type eq 'leaf') {
            my $v = $elt->fetch($mode) ;
            $result .= $self->write_line($name,$v,$note);
        }
        elsif ($type eq 'check_list') {
            my $v = $elt->fetch($mode) ;
            $result .= $self->write_line($name,$v,$note);
        }
        elsif ($type eq 'list') {
            $result .= $self->write_data_and_comments('#', undef, $note) ;
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

# ABSTRACT: Role to write OpenSsh config files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Role::Writer - Role to write OpenSsh config files

=head1 VERSION

version v2.7.9.1

=head1 SYNOPSIS

None. Consumed by L<Config::Model::Backend::OpenSsh::Ssh> and
L<Config::Model::Backend::OpenSsh::Sshd>.

=head1 DESCRIPTION

Write methods used by both L<Config::Model::Backend::OpenSsh::Ssh> and
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
