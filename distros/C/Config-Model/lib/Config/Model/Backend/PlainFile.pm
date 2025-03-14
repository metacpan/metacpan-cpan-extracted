#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::PlainFile 2.155;

use 5.10.1;
use Carp;
use Mouse;
use Config::Model::Exception;
use Path::Tiny;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

with "Config::Model::Role::ComputeFunction";
with "Config::Model::Role::FileHandler";

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

my $logger = get_logger("Backend::PlainFile");

sub annotation { return 0; }

# remember that a read backend (and its config file(s)) is attached to a node
# OTOH, PlainFile backend deal with files that are attached to elements of a node.
# Hence the files must not be managed by backend manager.

# file not opened by BackendMgr
# file_path is undef
sub skip_open { return 1; }

sub get_file_name {
    my ($self, %args) = @_;

    my $obj = $args{object}->fetch_element( name => $args{elt} );
    return $args{file} ? $obj->compute_string($args{file}) : $args{elt};
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub read ($self, %args) {
    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $check = $args{check} || 'yes';
    my $node  = $args{object};
    $logger->trace( "called on node ", $node->name );

    # read data from leaf element from the node
    # do not trigger warp when getting element names
    foreach my $elt ( $node->get_element_names(all => 1) ) {
        my $obj = $args{object}->fetch_element( name => $elt );

        my $file_name = $self->get_file_name(%args, elt => $elt);
        my $dir = $self->get_tuned_config_dir(%args);
        my $file = $dir->child($file_name);

        $logger->trace("looking to read plainfile $file for ", $obj->location);

        my $type = $obj->get_type;

        if ( $type eq 'leaf' ) {
            $self->read_leaf( $obj, $elt, $check, $file, \%args );
        }
        elsif ( $type eq 'list' ) {
            $self->read_list( $obj, $elt, $check, $file, \%args );
        }
        elsif ( $type eq 'hash' ) {
            $self->read_hash( $obj, $elt, $check, $file, \%args );
        }
        else {
            $logger->debug("PlainFile read skipped $type $elt");
        }

    }

    return 1;
}

sub read_leaf {
    my ( $self, $obj, $elt, $check, $file, $args ) = @_;

    return unless $file->exists;

    my $v = $file->slurp_utf8;
    chomp($v) unless $obj->value_type eq 'string';
    if ($logger->is_trace) {
        (my $str = $v) =~ s/\n.*/[...]/s;
        $logger->trace("storing leaf value '$str' from $file ");
    }
    $obj->store( value => $v, check => $check );
    return;
}

sub read_list {
    my ( $self, $obj, $elt, $check, $file, $args ) = @_;

    return unless $file->exists;

    my @v = $file->lines_utf8({ chomp => 1});
    $logger->trace("storing list value @v from $file ");

    $obj->store_set(@v);
    return;
}

sub read_hash {
    my ( $self, $obj, $elt, $check, $file, $args ) = @_;
    $logger->debug("PlainFile read skipped hash $elt");
    return;
}

sub write ($self, %args){
    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path read
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $check = $args{check} || 'yes';
    my $cfg_dir = $args{config_dir};
    my $dir = $self->get_tuned_config_dir(%args);
    $dir->mkpath({ mode => oct(755) } ) unless $dir->is_dir;

    my $node = $args{object};
    $logger->debug( "PlainFile write called on node ", $node->name );

    # write data from leaf element from the node
    foreach my $elt ( $node->get_element_name() ) {
        my $obj = $args{object}->fetch_element( name => $elt );

        my $file_name = $self->get_file_name(%args, elt => $elt);
        my $file = $dir->child($file_name);

        $logger->trace("looking to write plainfile $file for ", $obj->location);

        my $type = $obj->get_type;
        my @v;

        if ( $type eq 'leaf' ) {
            my $v = $obj->fetch( check => $args{check} );
            $v .= "\n" if defined $v and $obj->value_type ne 'string';
            push @v, $v if defined $v;
        }
        elsif ( $type eq 'list' ) {
            @v = map { "$_\n" } $obj->fetch_all_values;
        }
        else {
            $logger->debug("PlainFile write skipped $type $elt");
            next;
        }

        if (@v) {
            $logger->trace("PlainFile write opening $file to write $elt");
            $file->spew_utf8(@v);
            $file->chmod($args{file_mode}) if $args{file_mode};
        }
        elsif ($file->exists) {
            $logger->trace("PlainFile delete $file");
            $file->remove;
        }
    }

    return 1;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete ($self, %args) {
    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path read
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $dir = $self->get_tuned_config_dir(%args);
    my $node = $args{object};
    $logger->debug( "PlainFile delete called on deleted node");

    # write data from leaf element from the node
    foreach my $elt ( $node->get_element_name() ) {
        my $obj = $node->fetch_element( name => $elt );

        my $file_name = $self->get_file_name(%args, elt => $elt);
        my $file = $dir->child( $file_name );
        $logger->info( "Removing $file (deleted node)" );
        $file->remove;
    }
    return;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Read and write config as plain file

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::PlainFile - Read and write config as plain file

=head1 VERSION

version 2.155

=head1 SYNOPSIS

 use Config::Model;

 my $model = Config::Model->new;

 my $inst = $model->create_config_class(
    name => "WithPlainFile",
    element => [ 
        [qw/source new/] => { qw/type leaf value_type uniline/ },
    ],
    rw_config  => {
      backend => 'plain_file',
      config_dir => '/tmp',
    },
 );
 
 my $inst = $model->instance(root_class_name => 'WithPlainFile' );
 my $root = $inst->config_root ;

 $root->load('source=foo new=yes' );

 $inst->write_back ;

Now C</tmp> directory contains 2 files: C<source> and C<new>
with C<foo> and C<yes> inside.

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written in several files.
Each element of the node is written in a plain file.

=head1 Element type and file mapping

Element values are written in one or several files depending on their type.

=over

=item leaf

The leaf value is written in one file. This file can have several lines if the leaf
type is C<string>

=item list

The list content is written in one file. Each line of the file is a
value of the list.

=item hash

Not supported

=back

=head1 File mapping

By default, the configuration file is named after the element name
(like in synopsis above).

The C<file> parameter can also be used to specify a file name that
take into account the path in the tree using C<&index()> and
C<&element()> functions from L<Config::Model::Role::ComputeFunction>.

For instance, with the following model:

    class_name => "Foo",
    element => [
        string_a => { type => 'leaf', value_type => 'string'}
        string_b => { type => 'leaf', value_type => 'string'}
    ],
    rw_config => {
        backend => 'PlainFile',
        config_dir => 'foo',
        file => '&element(-).&element',
        file_mode => 0644,  # optional
    }

If the configuration is loaded with C<example string_a=something
string_b=else>, this backend writes "C<something>" in file
C<example.string_a> and C<else> in file C<example.string_b>.

C<file_mode> parameter can be used to set the mode of the written
file. C<file_mode> value can be in any form supported by
L<Path::Tiny/chmod>.

=head1 Methods

=head2 read_leaf

Parameters: C<(obj, elt, check, file, args)>

Called by L<read> method to read the file of a leaf element. C<args>
contains the arguments passed to L<read> method.

=head2 read_hash (obj,elt,check,file,args);

Like L<read_leaf> for hash elements.

=head2 read_list

Parameters: C<(obj, elt, check, file, args)>

Like L<read_leaf> for list elements.

=head2 write

C<write> writes a file for each element of the calling class. Works only for
leaf and list elements. Other element type are skipped. Always return 1 (unless it died before).

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::BackendMgr>, 
L<Config::Model::Backend::Any>, 

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
