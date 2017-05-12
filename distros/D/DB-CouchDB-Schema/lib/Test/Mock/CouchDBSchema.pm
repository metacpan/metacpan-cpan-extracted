package Test::Mock::CouchDBSchema;
use DB::CouchDB::Schema;
use Moose;
use Moose::Util::TypeConstraints;
use Carp;

=head1 NAME

Test::Mock::CouchDBSchema - A module to make mocking a DB::CouchDB::Schema easier

=head1 SYNOPSIS

=cut

#TODO(jwall): Lots and lots of POD

has mocked_views => ( is => 'rw', isa => 'HashRef[CodeRef]', required => 1,
                     default => sub { return {}; } );

has mocked_docs => ( is => 'rw', isa => 'HashRef[HashRef]', required => 1,
                    default => sub { return {}; } );

has mock_schema => ( is => 'rw', isa => 'ArrayRef', required => 1,
                    default => sub { return []; } );

sub BUILD {
    my $self = shift;
    #when we have loaded this module we want to prevent schema loads
    my $mock_schema = sub {
        my $otherself = shift;
        $otherself->schema($self->mock_schema());
        return $otherself;
    };
    my $mock_schema_from_db_method = sub {
        my $next = shift;
        $self->{orig_schema_from_db_method} = $next;
        return $mock_schema->(@_);
    };
    my $mock_schema_from_script_method = sub {
        my $next = shift;
        $self->{orig_schema_from_script_method} = $next;
        return $mock_schema->(@_);
    };

    DB::CouchDB::Schema->meta
        ->add_around_method_modifier(
            'load_schema_from_db' => $mock_schema_from_db_method);

    DB::CouchDB::Schema->meta
        ->add_around_method_modifier(
            'load_schema_from_script' => $mock_schema_from_db_method);

    my $mock_get = sub {
        my $next = shift;
        my $origself = shift;
        my $docname = shift;
        return DB::CouchDB::Result
            ->new($self->mocked_docs()->{$docname} || {} );
    };

    DB::CouchDB::Schema->meta
        ->add_around_method_modifier(
            'get' => $mock_get );

}

sub mock_view {
    my $self = shift;
    my $view_name = shift;
    my $view_rows = shift;
    
    my $method_body = sub {
        return DB::CouchDB::Iter->new( { rows => $view_rows } );
    };
    
    my $mocked = $self->mocked_views();
    $mocked->{$view_name} = $method_body;
    $self->mocked_views($mocked);
    
    DB::CouchDB::Schema->meta->add_method($view_name, $method_body);
    
    return $self;
}

sub unmock_view {
    my $self = shift;
    my $view_name = shift;
    croak "request to unmock $view_name when it is not mocked!!"
        if !defined $self->mocked_views()->{$view_name};
    delete $self->mocked_views()->{$view_name}; 
    DB::CouchDB::Schema->meta->remove_method($view_name);
    return $self;
}

sub unmock_all_views {
    my $self = shift;
    my @mocks = keys %{ $self->mocked_views() };
    
    for my $mocked ( @mocks ) {
        $self->unmock_view($mocked);
    }
    return $self;
}

sub mock_doc {
    my $self = shift;
    my $docname = shift;
    my $doc = shift;
    my $mocked = $self->mocked_docs();
    $mocked->{$docname} = $doc;
    $self->mocked_docs($mocked);
    return $self;
}

sub unmock_doc {
    my $self = shift;
    my $docname = shift;
    my $mocked = $self->mocked_docs();
    delete $mocked->{$docname};
    return $self;
}

sub unmock_all_docs {
    my $self = shift;
    my @mocks = keys %{ $self->mocked_docs() };
    
    for my $mocked ( @mocks ) {
        $self->unmock_doc($mocked);
    }
    return $self;
}

sub unmock_all {
    my $self = shift;
    $self->unmock_all_views();
    $self->unmock_all_docs();
    return $self;
}

1;
