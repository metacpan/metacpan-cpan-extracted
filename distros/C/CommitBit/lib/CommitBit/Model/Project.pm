use strict;
use warnings;

package CommitBit::Model::Project;
use Jifty::DBI::Schema;

use CommitBit::Model::Repository;

use CommitBit::Record schema {
    column 'name' =>
        type is 'text';
    column 'blurb' => 
        type is 'text',
        render_as 'textarea',
        since '0.0.2';
    column 'description' => 
        type is 'text';
    column 'root_path' =>
        type is 'text';
    column 'repository' =>
        is immutable,
        refers_to CommitBit::Model::Repository;

    column 'logo_url' => 
        type is 'text',
        since '0.0.3';

    column 'svn_url_anon' => type is 'text';
    column 'svn_url_auth' => type is 'text';
    column 'svnweb_url' => type is 'text';
    column 'wiki_url' => type is 'text';
    column 'bugtracker_url' => type is 'text';
    column 'lists_url' => type is 'text';
    column 'license' => type is 'text',
        valid_values are ('GPLv2' ,'Perl 5.8', 'Artistic 2.0', 'BSD', 'MIT', 'Death and repudiation');

    column 'featured' =>
        type is 'boolean',
        default is 'false',
        since '0.0.2';
    column 'publicly_visible' =>
        type is 'boolean',
        default is 'true';

};

# Your model-specific methods go here.

sub create {
    my $self = shift;
    my $args = { @_ };
    my ($id, $msg) = $self->SUPER::create(%$args);

    if ($id) {
	$self->repository->add_project($self);
    }
    return ($id, $msg);

}


sub _related_people {
    my $self = shift;
    my $members = CommitBit::Model::UserCollection->new();
    my $projmembers =$members->join( alias1 => 'main', column1=>'id', table2 => 'project_members', column2 => 'person');
    $members->limit(alias =>$projmembers, column => 'project', value => $self->id);
    return $projmembers => $members;
}


sub people {
    my $self = shift;
    my ($projmembers,$members) = $self->_related_people();
    return $members;
}


sub observers {
    my $self = shift;
    my ($projmembers,$members) = $self->_related_people();
    $members->limit(alias => $projmembers, column => 'access_level', operator => '=', value => 'observer', entry_aggregator => 'or');
    return $members;
}

sub members {
    my $self = shift;
    my ($projmembers,$members) = $self->_related_people();
    $members->limit(alias => $projmembers, column => 'access_level', operator => '=', value => 'author', entry_aggregator => 'or');
    return $members;
}

sub administrators {
    my $self = shift;
    my ($projmembers,$members) = $self->_related_people();
    $members->limit(alias => $projmembers, column => 'access_level', operator => '=', value => 'administrator', entry_aggregator => 'or');
    return $members;
}


sub is_project_admin {
    my $self = shift;
    my $person = shift; # user or currentuser

    my $administrators = $self->administrators();
    $administrators->limit( column => 'id', value =>$person->id);
    return $administrators->count;

} 

sub current_user_can {
    my $self = shift;
    my $right = shift;
    if ($right eq 'read') { return 1 }
    if (($right eq 'create' or $right eq 'update' or $right eq 'delete') and ($self->current_user->user_object && $self->current_user->user_object->admin)) {
        return 1;
    }
    if (( $right eq 'update' or $right eq 'delete') and $self->is_project_admin($self->current_user)) {
        return 1;
    }
    $self->SUPER::current_user_can($right => @_);

}


1;

