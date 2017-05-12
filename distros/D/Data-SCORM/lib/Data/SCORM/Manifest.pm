package Data::SCORM::Manifest;

use Any::Moose;
use Any::Moose qw/ X::AttributeHelpers /;
use XML::Twig;
use Data::SCORM::Organization;
use Data::SCORM::Item;
use Data::SCORM::Resource;
use JSON::Any;

use Data::Dumper;

=head1 NAME

Data::SCORM::Manifest - represent the Manifest

=head1 SYNOPSIS

    use Data::SCORM::Manifest;

    my $foo = Data::SCORM::Manifest->new();
    ...

=cut

has 'metadata' => (
	metaclass => 'Collection::Hash',
	is        => 'rw',
	isa       => 'HashRef',
	default   => sub { +{} },
	provides  => {
		exists => 'has_metadata',
		keys   => 'metadata_ids',
		get    => 'get_metadata',
		set    => 'set_metadata',
		},
	);

has 'organizations' => (
	metaclass => 'Collection::Hash',
	is        => 'rw',
	isa       => 'HashRef[Data::SCORM::Organization]',
	default   => sub { +{} },
	provides  => {
		exists => 'has_organization',
		keys   => 'organization_ids',
		get    => 'get_organization',
		set    => 'set_organization',
		},
	);

has 'resources' => (
	metaclass => 'Collection::Hash',
	is        => 'rw',
	isa       => 'HashRef',
	default   => sub { +{} },
	provides  => {
		exists => 'has_resource',
		keys   => 'resource_ids',
		get    => 'get_resource',
		set    => 'set_resource',
		},
	);

sub _simplify {
	my $node = shift;
	my $data = $node->simplify;
	return {
		map {
			my $v = $data->{$_};
			(my $k = $_) =~ s/^adlseq://;
			($k => $v);
		  }
		  keys %$data
	  };
}

around 'new' => sub {
	my ($code, @params) = @_;
	my $self = $code->(@params);
	for my $org (values %{$self->organizations}) {
		for my $item ($org->all_items) {
			my $id = $item->identifierref or next;
			if (my $resource = $self->get_resource($id)) {
                $item->resource($resource);
            }
            else {
				warn "Couldn't get resource $id, if it is an Aggregation item (only contains children) then it should not have an identifierredf";
            }
		}
	}
	return $self;
  };

sub get_default_organization {
	my ($self) = @_;
	return $self->get_organization('default');
}

sub parsefile {
	my ($class, $file) = @_;

	my %data;

	# TODO: consider whether I want to create the objects from HoH structures
	#       /here/ or to do it in coercions in each class

	my $t = XML::Twig->new(
		twig_handlers => {
			'manifest/metadata' => sub { 
				my ($t, $metadata) = @_;
				$data{metadata} = _simplify($metadata);
				# alternatively $metadata->findnodes('lom:lom')... etc. ->delete
				# i.e. to do something cleverer with lom:lom
			  },
			'manifest/organizations' => sub {
				my ($t, $organizations) = @_;
				my $default = $organizations->att('default'); # required
				my %organizations = map { 
					my $id = $_->att('identifier');
					# we want only <item> to be an array
					my @items = map { 
						$_->delete; 
						Data::SCORM::Item->new(%{ 
							_simplify($_) 
						})
						} 
						$_->findnodes('item');
					my $org = $_->simplify;
					$org->{items} = \@items;

					($id => Data::SCORM::Organization->new( %$org ))
					}
					$organizations->children; 
					# findnodes('organization')
				$organizations{default} = $organizations{$default};
				$data{organizations} = \%organizations;
			  },
			'manifest/resources' => sub {
				my ($t, $resources) = @_;
				my %resources = map 
					{ 
					  my $res = _simplify($_);
					  my $res_object = Data::SCORM::Resource->new(%$res);
					  # warn Dumper($res, $res_object);
					  ($_->att('identifier') => $res_object);
					}
					$resources->children; 
					# findnodes('resource')
				$data{resources} = \%resources;
			  },
		  }
	  );

	# we could just let it die, or use safe_parsefile, but I think it's useful
	# to wrap the error message
	eval {
		$t->parsefile( $file )
		};
	die "Couldn't parse SCORM manifest $file\: $@" if $@;

	return $class->new(%data);
}

sub as_hoh {
	# turn this into a normal perl data structure that we can jsonnify
	my ($self, $url_base) = @_;
	$url_base ||= '';

	my %organizations = map {
		my $org_name = $_;
		my $org = $self->get_organization($org_name);
		my @resources = map {
			my $id  = $_->identifierref;
			my $res = $self->get_resource($id);
			my @files = map {
				"$url_base/$_->{href}"
			  } $res->all_files;
			+{ %$res, file => \@files }; # naive object flattening
		  } $org->all_items;

		my %org = %$org;
		$org{resources} = \@resources;

        my @items = map { 
            my $item = { %$_ };
            $item->{resource} = { %{ $item->{resource} } };
            $item;
            } @{ $org{items} };
        $org{items} = \@items;

		( $org_name => \%org );
	  } $self->organization_ids;

	return {
		metadata      => +{ %{$self->metadata} },
		organizations => \%organizations,
	  };
}

sub to_json {
	my $self = shift;
	my $hoh = $self->as_hoh(@_); # e.g. the $url_base param
	my $js = JSON::Any->new( allow_blessed => 1 );
	return $js->to_json($hoh);
}

# __PACKAGE__->make_immutable;
no Any::Moose;

=head1 AUTHOR

osfameron, C<< <osfameron at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-scorm-manifest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SCORM-Manifest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SCORM::Manifest

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SCORM-Manifest>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SCORM-Manifest/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 OSFAMERON.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::SCORM::Manifest
