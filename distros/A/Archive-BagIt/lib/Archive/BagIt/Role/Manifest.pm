package Archive::BagIt::Role::Manifest;
use strict;
use warnings;
use namespace::autoclean;
use Carp qw( croak carp );
use File::Spec ();
use Moo::Role;
with 'Archive::BagIt::Role::Plugin';
with 'Archive::BagIt::Role::Portability';
# ABSTRACT: A role that handles all manifest files for a specific Algorithm
our $VERSION = '0.098'; # VERSION

has 'algorithm' => (
    is => 'rw',
    #isa=>'HashRef',
);

has 'manifest_file' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_manifest_file',
);

sub _build_manifest_file {
    my $self = shift;
    my $algorithm = $self->algorithm()->name;
    my $file = File::Spec->catfile($self->bagit->metadata_path, "manifest-$algorithm.txt");
    if (-f $file) {
        return $file;
    }
    return;
}


has 'tagmanifest_file' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_tagmanifest_file'
);

sub _build_tagmanifest_file {
    my $self = shift;
    my $algorithm = $self->algorithm()->name;
    my $file = File::Spec->catfile( $self->bagit->metadata_path, "tagmanifest-$algorithm.txt");
    if (-f $file) {
        return $file;
    }
    return;
}

sub BUILD {}

after BUILD => sub {
    my $self = shift;
    my $algorithm = $self->algorithm->name;
    $self->{bagit}->{manifests}->{$algorithm} = $self;
};

has 'parallel_support' => (
    is        => 'ro',
    builder   => '_check_parallel_support',
    predicate => 1,
    lazy      => 1,
);

sub _check_parallel_support {
    my $self = shift;
    my $class = 'Parallel::parallel_map';
    if (!exists $INC{'Parallel/parallel_map.pm'}) {
        carp "Module '$class' not available, disable parallel support";
        $self->bagit->use_parallel( 0 );
        return 0;
    }
    load_class($class);
    $class->import( 'parallel_map' );
    return 1;
}

sub check_pluggable_modules() {
    my $self = shift;
    return ($self->has_parallel_support() && $self->has_async_support());
}



has 'manifest_entries' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_manifest_entries',
);


has 'tagmanifest_entries' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_tagmanifest_entries',
);

sub __build_xxxmanifest_entries {
    my ($self, $xxmanifest_file) = @_;
    my $xxmanifest_entries = {};
    my $algorithm = $self->algorithm()->name;
    open(my $XXMANIFEST, "<:encoding(UTF-8)", $xxmanifest_file) or croak("Cannot open $xxmanifest_file: $!");
    while (my $line = <$XXMANIFEST>) {
        $line = chomp_portable($line);
        my ($digest, $file) = split(/\s+/, $line, 2);
        next unless ((defined $digest) && (defined $file)); # empty lines!
        $xxmanifest_entries->{$file} = $digest;
    }
    close($XXMANIFEST);
    return $xxmanifest_entries;
}

sub _build_tagmanifest_entries {
    my ($self) = @_;
    my $tm_file = $self->tagmanifest_file();
    if (defined $tm_file) {
        return $self->__build_xxxmanifest_entries($tm_file);
    }
    return;
}

sub _build_manifest_entries {
    my ($self) = @_;
    my $m_file = $self->manifest_file();
    if (defined $m_file) {
        return $self->__build_xxxmanifest_entries($m_file);
    }
    return;
}

sub _fill_digest_hashref { # should be handle if empty values and ignore it (because parallel map)
    my ($self, $bagit, $localname) = @_;
    if ((!defined $localname) or (0 == length($localname)) ) {
        # croak "empty localname used!";
        return;
    }
    my $digest_hashref;
    my $fullname = File::Spec->catfile($bagit, $localname);
    my $calc_digest = $self->bagit->digest_callback();
    my $eval = &$calc_digest($self->algorithm(), $fullname);
    $digest_hashref->{calculated_digest} = $eval // '';
    $digest_hashref->{local_name} = $localname;
    $digest_hashref->{full_name} = $fullname;
    return $digest_hashref;
}




# calc digest
# expects expected_ref, array_ref of filenames
# returns arrayref of hashes where each entry has
# $tmp->{calculated_digest} = $digest;
# $tmp->{expected_digest} = $expected_digest;
# $tmp->{filename} = $filename;
sub calc_digests {
    my ($self, $bagit, $filenames_ref) = @_;
    $self->check_pluggable_modules(); # handles Modules
    my @digest_hashes;
    my %digest_results;
    if ($self->bagit->use_parallel()) {
        # Parallel::Map does not work at the moment, potential bug in Parallel::Map or IO::Async
        # @digest_hashes = pmap_scalar {
        #     $self->_fill_digest_hashref($bagit, $_);
        # } foreach => $filenames_ref;
        # works as expected:

        my $anon_sub = sub {
            my $filename = shift;
            return $self->_fill_digest_hashref($bagit, $filename);
        };
        ## no critic (ProhibitStringyEval);
        @digest_hashes = eval 'Parallel::parallel_map::parallel_map (
            sub { my $filename = shift; &$anon_sub($filename);}  , @{ $filenames_ref}
        )';
    } else {
        # serial variant
        @digest_hashes = map {$self->_fill_digest_hashref($bagit, $_)} @{$filenames_ref}
    }
    return \@digest_hashes;
}

sub _verify_XXX_manifests {
    my ($self, $xxprefix, $xxmanifest_entries, $files_ref, $return_all_errors) = @_;
    # Read the manifest file
    my @files = @{ $files_ref };
    my @invalid_messages;
    my $bagit = $self->bagit->bag_path;
    my $algorithm = $self->algorithm()->name;
    my $subref_invalid_report_or_die = sub {
        my $message = shift;
        if (defined $return_all_errors) {
            push @invalid_messages, $message;
        } else {
            croak($message);
        }
        return;
    };
    # Test readability
    foreach my $local_name (@files) {
        # local_name is relative to bagit base
        my $filepath = File::Spec->catfile($bagit, $local_name);
        unless (-r $filepath) {
            &$subref_invalid_report_or_die(
                "cannot read $local_name (bag-path:$bagit)",
            );
        }
    }
    # Evaluate each file against the manifest

    my $local_xxfilename = "${xxprefix}-${algorithm}.txt";

    # first check if each file from payload exists in manifest_entries for given alg
    foreach my $local_name (@files) {
        my $normalized_local_name = normalize_payload_filepath($local_name);
        # local_name is relative to bagit base
        unless (exists $xxmanifest_entries->{$normalized_local_name}) { # localname as value should exist!
            &$subref_invalid_report_or_die(
                "file '$local_name' (normalized='$normalized_local_name') found, which is not in '$local_xxfilename' (bag-path:'$bagit')!"
                    #."DEBUG: \n".join("\n", keys %{$xxmanifest_entries->{$algorithm}})
            );
        }
    }
    # second check if each file from manifest_entries for given alg exists in payload
    my %normalised_files;
    foreach my $file (@files) {
        $normalised_files{ normalize_payload_filepath( $file )} = 1;
    }
    foreach my $local_mf_entry_path (keys %{$xxmanifest_entries}) {
        if ( # to avoid escapes via manifest-files
            check_if_payload_filepath_violates($local_mf_entry_path)
        ) {
            &$subref_invalid_report_or_die("file '$local_mf_entry_path' not allowed in '$local_xxfilename' (bag-path:'$bagit'")
        }
        else {
            unless (exists $normalised_files{$local_mf_entry_path}) {
                &$subref_invalid_report_or_die(
                    "file '$local_mf_entry_path' NOT found, but expected via '$local_xxfilename' (bag-path:'$bagit')!"
                );
            }
        }
    }
    # all preconditions full filled, now calc all digests
    my $digest_hashes_ref = $self->calc_digests($bagit, \@files);
    # compare digests
    if (defined $digest_hashes_ref && (ref $digest_hashes_ref eq 'ARRAY')) {
        foreach my $digest_entry (@{$digest_hashes_ref}) {
            my $normalized = normalize_payload_filepath($digest_entry->{local_name});
            $digest_entry->{expected_digest} = $xxmanifest_entries->{$normalized};
            if (! defined $digest_entry->{expected_digest} ) { next; } # undef expected digests only occur if all preconditions fullfilled but return_all_errors was set, we should ignore it!
            if ($digest_entry->{calculated_digest} ne $digest_entry->{expected_digest}) {
                my $xxfilename = File::Spec->catfile($bagit, $local_xxfilename);
                &$subref_invalid_report_or_die(
                    sprintf("file '%s' (normalized='%s') invalid, digest (%s) calculated=%s, but expected=%s in file '%s'",
                        $digest_entry->{local_name},
                        $normalized,
                        $algorithm,
                        $digest_entry->{calculated_digest},
                        $digest_entry->{expected_digest},
                        $xxfilename
                    )
                );
            }
        }
    }

    if ($return_all_errors && (scalar @invalid_messages > 0)) {
        push @{$self->bagit->{errors}},
            join("\n\t",
                sort @invalid_messages
            );
        return;
    }
    return 1;
}


sub verify_manifest {
    my ($self, $payload_files_ref, $return_all_errors) = @_;
    if ($self->manifest_file()) {
        return $self->_verify_XXX_manifests(
            "manifest",
            $self->manifest_entries(),
            $payload_files_ref,
            $return_all_errors
        );
    }
    return;
}


sub verify_tagmanifest {
    my ($self, $non_payload_files_ref, $return_all_errors) = @_;
    my @non_payload_files = grep {$_ !~ m#tagmanifest-[0-9a-zA-Z]+\.txt$#} @{ $non_payload_files_ref };
    if ($self->tagmanifest_file()) {
        return $self->_verify_XXX_manifests(
            "tagmanifest",
            $self->tagmanifest_entries(),
            \@non_payload_files,
            $return_all_errors
        );
    }
    return;
}

sub __create_xxmanifest {
    my ($self, $prefix, $files_ref) = @_;
    my $algo = $self->algorithm->name;
    my $bagit = $self->bagit->bag_path;
    my $manifest_file = File::Spec->catfile($self->bagit->metadata_path, "$prefix-${algo}.txt");
    # Generate digests for all of the files under ./data
    my $digest_hashes_ref = $self->calc_digests($bagit, $files_ref);
    if (defined $digest_hashes_ref && (ref $digest_hashes_ref eq 'ARRAY')) {
        open(my $fh, ">:encoding(UTF-8)",$manifest_file) or croak("Cannot create $prefix-${algo}.txt: $!\n");
        foreach my $digest_entry (@{$digest_hashes_ref}) {
            my $normalized_file = normalize_payload_filepath($digest_entry->{local_name});
            my $digest = $digest_entry->{calculated_digest};
            print($fh "$digest  $normalized_file\n");
        }
        close($fh);
    }
    return 1;
}


sub create_manifest {
    my ($self) = @_;
    $self->__create_xxmanifest('manifest', $self->bagit->payload_files);
    return 1;
}


sub create_tagmanifest {
    my ($self) = @_;
    my @non_payload_files = grep {$_ !~ m#^tagmanifest-.*\.txt$#} @{ $self->bagit->non_payload_files };
    $self->__create_xxmanifest('tagmanifest', \@non_payload_files);
    return 1;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Manifest - A role that handles all manifest files for a specific Algorithm

=head1 VERSION

version 0.098

=head2 manifest_entries()

returns the manifest_entries() for the current digest algorithm, the result is hashref like:

   {
       data/hello.txt   "e7c22b994c59d9cf2b48e549b1e24666636045930d3da7c1acb299d1c3b7f931f94aae41edda2c2b207a36e10f8bcb8d45223e54878f5b316e7ce3b6bc019629"
   }

=head2 tagmanifest_entries()

returns the tagmanifest_entries() for the current digest algorithm, the result is hashref, see L<manifest_entries()>

=head2 calc_digests($bagit, $filenames_ref, $opts)

Method to calculate and return all digests for a a list of files. This method will be overwritten by L<Archive::BagIt::Fast>.

=head2 verify_manifest($payload_files, $return_all_errors)

check fixities of payload files in both directions

=head2 verify_tagmanifest($non_payload_files, $return_all_errors)

check fixities of non-payload files in both directions

=head2 create_manifest()

creates a new manifest file for payload files

=head2 create_tagmanifest()

creates a new tagmanifest file for non payload files

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
