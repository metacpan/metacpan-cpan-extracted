package Algorithm::Classifier::IsolationForest::App::Command::proto;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp qw(read_file write_file);

sub opt_spec {
	return (
		[
			'from-model=s',
			'Extract a prototype from this saved model JSON (batch or online).',
			{ 'completion' => 'files' }
		],
		[
			'check=s',
			'Validate this prototype file and print a summary of it; exits non-zero when invalid.',
			{ 'completion' => 'files' }
		],
		[
			'o=s',
			'Output the prototype to this file instead of printing (--from-model only).',
			{ 'completion' => 'files' }
		],
		[ 'w', 'If the file specified via -o exists, over write it.' ],
	);
} ## end sub opt_spec

sub abstract { 'Extract a prototype from a saved model, or validate a prototype file' }

sub description {
	'Works with model prototypes: small JSON documents holding the variable
schema (feature names, per-feature descriptions, munger specs, missing
policy), a user-owned schema_version and schema_description, and
optionally the tuning knobs.  `iforest fit --prototype` and
`iforest stream --prototype` create models from one; see PROTOTYPES in
the Algorithm::Classifier::IsolationForest POD for the file format.

--from-model extracts a prototype from a saved model, closing the loop:
pull the schema and knobs out of a good model, edit the metadata, and
create fresh models from it.  A model with no recorded schema_version /
schema_description gets placeholder values to edit in.

--check validates a prototype file and prints a summary of what it
describes, exiting non-zero when the file is not a valid prototype.

Exactly one of --from-model or --check must be given.
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	my $from  = defined $opt->{'from_model'} ? 1 : 0;
	my $check = defined $opt->{'check'}      ? 1 : 0;
	if ( $from + $check != 1 ) {
		$self->usage_error('exactly one of --from-model or --check must be specified');
	}

	my ( $switch, $file ) = $from ? ( '--from-model', $opt->{'from_model'} ) : ( '--check', $opt->{'check'} );
	if ( !-f $file ) {
		$self->usage_error( $switch . ', "' . $file . '", is not a file or does not exist' );
	} elsif ( !-r $file ) {
		$self->usage_error( $switch . ', "' . $file . '", is not readable' );
	}

	if ( defined $opt->{'o'} ) {
		if ($check) {
			$self->usage_error('-o may only be used with --from-model');
		}
		if ( -e $opt->{'o'} && !$opt->{'w'} ) {
			$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );
		}
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	if ( defined $opt->{'from_model'} ) {
		my $model      = Algorithm::Classifier::IsolationForest->load( $opt->{'from_model'} );
		my $proto_json = $model->to_prototype;
		if ( defined $opt->{'o'} ) {
			write_file( $opt->{'o'}, { 'atomic' => 1 }, $proto_json . "\n" );
		} else {
			print $proto_json. "\n";
		}
		return 1;
	} ## end if ( defined $opt->{'from_model'} )

	# --check: structural validation plus a human summary of the file.
	my $raw   = read_file( $opt->{'check'} );
	my $proto = eval { Algorithm::Classifier::IsolationForest->validate_prototype($raw) };
	die( '--check, "' . $opt->{'check'} . '", is not a valid prototype: ' . $@ ) if $@;

	my $schema = $proto->{schema};
	my $tags   = $schema->{feature_names};
	printf "  %-20s  %s\n", 'file',               $opt->{'check'};
	printf "  %-20s  %s\n", 'class',              $proto->{class};
	printf "  %-20s  %s\n", 'schema_version',     $proto->{schema_version};
	printf "  %-20s  %s\n", 'schema_description', $proto->{schema_description};
	printf "  %-20s  %s\n", 'missing', ( defined $schema->{missing} ? $schema->{missing} : '(unset)' );
	printf "  %-20s  %s\n", 'feature_names', join( ', ', @$tags );
	my $fd = ref $schema->{feature_descriptions} eq 'HASH' ? $schema->{feature_descriptions} : {};

	for my $i ( 0 .. $#$tags ) {
		printf "    [%d]  %s%s\n", $i, $tags->[$i],
			( defined $fd->{ $tags->[$i] } ? ' -- ' . $fd->{ $tags->[$i] } : '' );
	}
	my $mungers = $schema->{mungers};
	if ( ref $mungers eq 'HASH' && %$mungers ) {
		printf "  %-20s  %s\n", 'mungers', scalar( keys %$mungers ) . ' configured';
		for my $k ( sort keys %$mungers ) {
			printf "    %-18s  %s\n", $k,
				( ref $mungers->{$k} eq 'HASH' && defined $mungers->{$k}{munger} ? $mungers->{$k}{munger} : '(?)' );
		}
	}
	my $params = ref $proto->{params} eq 'HASH' ? $proto->{params} : {};
	for my $k ( sort keys %$params ) {
		printf "  %-20s  %s\n", $k, ( defined $params->{$k} ? $params->{$k} : '(unset)' );
	}

	return 1;
} ## end sub execute

return 1;
