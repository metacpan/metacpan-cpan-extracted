package Test::Framework;

#use FindBin::lib;
use Test::More;
use DBIx::Patcher::Schema;

{
    my $schema;
    sub get_schema {
        $schema ||= DBIx::Patcher::Schema->connect(
            'dbi:Pg:dbname=patcher;host=localhost',
            'www',
            '',
        );

        #    undef,

        return $schema;
    }

    sub uniq_name {
        my($self,$name) = @_;
        return (defined $name ? $name : '') .' - '. time;
    }

    sub create_run {
        my($self) = @_;

        return $self->get_schema->resultset('Patcher::Run')->create_run();
    }

    sub search_file {
        my($self,$file) = @_;

        return $self->get_schema->resultset('Patcher::Patch')
            ->search_file($file);
    }
#
#    sub get_node {
#        my($self,$args) = @_;
##        $args->{name} .= ' - '. time;
#
#        return $self->get_schema->resultset('Meta::Node')->get_node($args);
#    }
#
#    sub get_roots {
#        my($self) = @_;
#
#        return $self->get_schema->resultset('Meta::Node')->roots;
#    }
#
#    sub add_type {
#        my($self,$args) = @_;
#        $args->{name} = $self->uniq_name($args->{name});
#        use Data::Dump qw/pp/;
#note pp($args);
#        return $self->get_schema->resultset('Meta::Type')->add_type($args);
#    }
#
#    sub get_type {
#        my($self,$args) = @_;
#
#        return $self->get_schema->resultset('Meta::Type')->get_type($args);
#    }
#
#    sub get_types {
#        my($self) = @_;
#
#        return $self->get_schema->resultset('Meta::Type')->types;
#    }
#
##    sub add_node {
##        my($self,$node,$args) = @_;
##        $args->{name} .= ' - '. time;
##use Data::Dump qw/pp/;
##warn pp($args);
##        return $node->add_node($args);
##    }
#
#    sub find_ilike_node {
#        my($self,$name) = @_;
#        my $schema = $self->get_schema;
#
#        my $set = $schema->resultset('Meta::Node')->search({
#            name => { ilike => "$name%" },
#        },{
#            order_by =>  'me.id DESC',
#        });
#
#        return $set->first;
#    }
#
#    sub filter_leaves {
#        my($self,$ids) = @_;
#        my $schema = $self->get_schema;
#
#        my $set = $schema->resultset('Meta::Node')->filter_leaves($ids);
#        return $set;
#    }
}



1;
