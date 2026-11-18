#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::DumpAsData 2.169;

use Carp;
use strict;
use warnings;
use 5.10.1;

use Config::Model::Exception;
use Config::Model::ObjTreeScanner;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

sub new {
    return bless {}, shift;
}

sub dump_as_data ($self, %args) {
    my $dump_node = delete $args{node}
        || croak "dump_as_data: missing 'node' parameter";
    my $mode = delete $args{mode} // '';
    my $ordered_hash_as_list_of_hashes = delete $args{ordered_hash_as_list_of_hashes} // 0;
    my $ordered_hash_key_name = delete $args{ordered_hash_key_name} // 'name';
    my $skip_aw = delete $args{skip_auto_write} || '';
    my $auto_v  = delete $args{auto_vivify}     || 0;
    my $ordered_hash_as_list = delete $args{ordered_hash_as_list} // 1;
    my $to_boolean = delete $args{to_boolean} // sub ($input) {return $input;};

    # mode and full_dump params are both accepted
    my $full = delete $args{full_dump} || 0;
    carp "dump_as_data: full_dump parameter is deprecated. Please use 'mode => user' instead"
        if $full;

    my $fetch_mode =
          $full           ? 'user'
        : $mode eq 'full' ? 'user'
        : $mode           ? $mode
        :                   'custom';

    my $std_cb = sub ($scanner, $data_r, $obj, $element, $index, $value_obj) {
        my $v = $value_obj->fetch(mode => $fetch_mode);
        # transform boolean type in boolean object
        $$data_r = $value_obj->value_type eq 'boolean' ? $to_boolean->($v) : $v;
        return;
    };

    my $check_list_element_cb = sub ($scanner, $data_r, $node, $element_name, @check_items) {
        my $a_ref = $node->fetch_element($element_name)->get_checked_list;

        # don't store empty checklist
        $$data_r = $a_ref if @$a_ref;
        return;
    };

    # ordered hash is written as list of { $key => $name, value =>
    # $value} for leaf cargo type, or a list of { $key => $name, %v }
    # for node cargo type.
    my $ordered_list_of_hash_element_cb = sub ($scanner, $data_ref, $node, $element_name, @keys) {
        my $force_write = $node->fetch_element($element_name)->write_empty_value;
        my $elt_type = $node->fetch_element($element_name)->get_cargo_type;

        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my @res;
        foreach my $k (@keys) {
            my $v;
            $scanner->scan_hash( \$v, $node, $element_name, $k );

            # don't create the key if $v is undef
            if (defined $v or $force_write) {
                # preserve order inside the ref, mostly useful for tests
                my $ref = {};
                $ref->{$ordered_hash_key_name} = $k;
                if ($elt_type =~ /node/) {
                    # merge $v hash into $ref
                    while (my ($subk, $subv) = each $v->%*) {
                        $ref->{$subk} = $subv;
                    }
                }
                else {
                    $ref->{value} = $v;
                }
                push @res, $ref;
            }
        } ;

        if (@res) {
            $data_ref->$* = \@res;
        }
    };

    my $ordered_hash_as_flat_list = sub ($scanner, $data_ref, $node, $element_name, @keys) {
        my $force_write = $node->fetch_element($element_name)->write_empty_value;

        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my @res;
        foreach my $k (@keys) {
            my $v;
            $scanner->scan_hash( \$v, $node, $element_name, $k );

            # don't create the key if $v is undef
            if (defined $v or $force_write) {
                push @res , $k, $v;
            }
        } ;

        if (@res) {
            $data_ref->$* = \@res;
        }
    };

    my $ordered_hash_element_cb = $ordered_hash_as_list_of_hashes ?
        $ordered_list_of_hash_element_cb : $ordered_hash_as_flat_list;

    my $hash_element_cb = sub ($scanner, $data_ref, $node, $element_name, @keys) {
        my $force_write = $node->fetch_element($element_name)->write_empty_value;

        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my $h = {};
        foreach my $k (@keys) {
            my $v;
            $scanner->scan_hash(\$v, $node, $element_name, $k);

            # don't create the key if $v is undef
            if (defined $v or $force_write) {
                $h->{$k} = $v;
            }
        } ;

        $data_ref->$* = $h if keys $h->%*;
    };

    my $list_element_cb = sub ($scanner, $data_ref, $node, $element_name, @idx) {
        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my @a;
        foreach my $i (@idx) {
            my $v;
            $scanner->scan_hash( \$v, $node, $element_name, $i );
            push @a, $v if defined $v;
        }
        $$data_ref = \@a if scalar @a;
        return;
    };

    my $node_content_cb = sub ($scanner, $data_ref, $node, @element) {
        my %h;
        foreach my $e (@element) {
            my $v;
            $scanner->scan_element( \$v, $node, $e );
            $h{$e} = $v if defined $v;
        }
        $$data_ref = \%h if scalar %h;
        return;
    };

    my $node_element_cb = sub ($scanner, $data_ref, $node, $element_name, $key, $next) {
        return if $skip_aw and $next->is_auto_write_for_type($skip_aw);

        $scanner->scan_node( $data_ref, $next );
        return;
    };

    my @scan_args = (
        check      => delete $args{check}      || 'yes',
        auto_vivify           => $auto_v,
        list_element_cb       => $list_element_cb,
        check_list_element_cb => $check_list_element_cb,
        hash_element_cb       => $hash_element_cb,
        ordered_hash_element_cb => $ordered_hash_element_cb,
        leaf_cb               => $std_cb,
        node_element_cb       => $node_element_cb,
        node_content_cb       => $node_content_cb,
    );

    my @left = keys %args;
    croak "DumpAsData: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my $obj_type = $dump_node->get_type;
    my $result;
    my $p = $dump_node->parent;
    my $e = $dump_node->element_name;
    my $i = $dump_node->index_value;    # defined only for hash and list

    if ( $obj_type =~ /node/ ) {
        $view_scanner->scan_node( \$result, $dump_node );
    }
    elsif ( defined $i ) {
        $view_scanner->scan_hash( \$result, $p, $e, $i );
    }
    elsif ($obj_type eq 'list'
        or $obj_type eq 'hash'
        or $obj_type eq 'leaf'
        or $obj_type eq 'check_list' ) {
        $view_scanner->scan_element( \$result, $p, $e );
    }
    else {
        croak "dump_as_data: unexpected type: $obj_type";
    }

    return $result;
}

1;

# ABSTRACT: Dump configuration content as a perl data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::DumpAsData - Dump configuration content as a perl data structure

=head1 VERSION

version 2.169

=head1 SYNOPSIS

 use Config::Model ;
 use Data::Dumper ;

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [
      {
        name => 'foo',
        type => 'leaf',
        value_type => 'string',
      },
      {
        name => 'bar',
        alias => 'foo',
      },
      {
        name => 'baz',
        type => 'hash',
        index_type => 'string',
        cargo => {
          type => 'leaf',
          value_type => 'string',
        },
      },
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put some data in config tree the hard way
 $root->fetch_element('foo')->store('yada') ;
 $root->fetch_element('bar')->store('bla bla') ;
 $root->fetch_element('baz')->fetch_with_id('en')->store('hello') ;

 # put more data the easy way
 my $steps = 'baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( steps => $steps ) ;

 print Dumper($root->dump_as_data);
 # $VAR1 = {
 #         'bar' => 'bla bla',
 #         'baz' => {
 #                    'en' => 'hello',
 #                    'fr' => 'bonjour',
 #                    'hr' => 'dobar dan'
 #                  },
 #         'foo' => 'yada'
 #       };

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to dump the content
of a configuration tree in perl data structure.

The perl data structure is a hash of hash. Only
L<CheckList|Config::Model::CheckList> content is stored in an array ref.

User can pass a sub reference to apply to values of boolean type. This
sub can be used to convert the value to an object representing a
boolean like L<boolean>. (since 2.129)

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure then
contains C<'a','b'>.

=head1 Dumping ordered hash

Dumping an ordered hash is a bit of a mess. Perl does not guarantee to
preserve hash key order. So some tricks must be used to dump an
ordered hash.

First, the ordered hash can be dumped as a list. In the examples
below, the key order is C<foo, bar>. So the hash:

 { foo => v1, bar => v2 }

is dumped as:

 [ foo => v1, bar => v2 ]

Another trick is to convert the ordered hash in a list of hash when
C<ordered_hash_as_list_of_hashes> parameter is true. For instance, the
ordered hash

 { foo => v1, bar => v2 }

can be converted in:

 [
   { name => 'foo', value => 'v1'},
   { name => 'bar', value => 'v2'},
 ]

Another issue, arises for ordered hash of node. Lets start from this
example written with a L<Config::Model::Loader> string:

 ordered_hash_of_node:z aa2=foo_x -
 ordered_hash_of_node:y aa2=foo_y ab2=bar_y -

A Perl dump with the same technique as above would yield:

  [
    {
      name => 'z',     # hash key
      value => {       # another hash to contain the node attribute values
        aa2 => 'foo_x'
      }
    },
    {
       name => 'y',
       value => {
         aa2 => 'foo_y',
         ab2 => 'bar_y'
       }
    }
   ]

which may be confusing due to additional hash level.

So the Perl dump is done merging the content of the node in the first
hash level:

 [
   {
     name => 'z,      # hash key
     aa2 => 'foo_x,   # node attribute
   },
   {
     name => 'y,      # hash key
     aa2 => 'foo_y,   # node attribute
     ab2 => 'bar_y,   # another node attribute
   }
 ]

The parameter C<ordered_hash_key_name> parameter can be used to
avoid a collision between a node attribute and the hash key.

For instance, calling

  $node->dump_as_data(
     ordered_hash_as_list_of_hashes => 1,
     ordered_hash_key_name => "my_unique_key"
  );

would yield:

 [
   {
     my_unique_key => 'z,
     aa2 => 'foo_x,
   },
   {
     my_unique_key => 'y,
     aa2 => 'foo_y,
     ab2 => 'bar_y,
   }
 ]

=head1 CONSTRUCTOR

=head2 new

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods

=head2 dump_as_data

Return a perl data structure

Parameters are:

=over

=item node

Reference to a L<Config::Model::Node> object. Mandatory

=item full_dump

Also dump default values in the data structure. Useful if the dumped
configuration data is used by the application. This parameter is
deprecated in favor of mode parameter.

=item mode

Note that C<mode> parameter is also accepted and overrides
C<full_dump> parameter. See L<Config::Model::Value/fetch> for
details on C<mode>.

=item ordered_hash_as_list_of_hashes

Boolean. Dump ordered hash as list of hashes. See L</Dumping ordered
hash> for details. Default is C<false>

=item ordered_hash_key_name

Key name to use when inserting original hash key in dumped hash
value. Default is C<name>.

For instance, if the original hash contains:

 { foo => v1, bar => v2 }

The original hash is dumped in this list of hashes:

 [
   { name => 'foo', value => 'v1'},
   { name => 'bar', value => 'v2'},
 ]

=item skip_auto_write

Skip node that have a C<perl write> capability in their model. See
L<Config::Model::BackendMgr>.

This option must be used when using DumpAsData: to write back
configuration data. When a configuration model contains several
backends (one at the tree root and others in tree nodes), setting this
option ensure that the "root" configuration file does not contain data
duplicated in configuration file of others tree nodes.

=item auto_vivify

Scan and create data for nodes elements even if no actual data was
stored in them. This may be useful to trap missing mandatory values.

=item ordered_hash_as_list

By default, ordered hash (i.e. the order of the keys are important)
are dumped as Perl list. This is the faster way to dump such hashed
while keeping the key order. But it's the less readable way.

When this parameter is 1 (default), the ordered hash is dumped as a
list:

  my_hash => [ A => 'foo', B => 'bar', C => 'baz' ]

When this parameter is set as 0, the ordered hash is dumped with a
special key that specifies the order of keys. E.g.:

  my_hash => {
   __my_hash_order => [ 'A', 'B', 'C' ] ,
   B => 'bar', A => 'foo', C => 'baz'
  }

=item to_boolean

Sub reference to map a value of type boolean to a boolean class (since
2.129). For instance:

 to_boolean => sub { boolean($_[0]); }

Default is C<sub { return $_[0] }>

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
