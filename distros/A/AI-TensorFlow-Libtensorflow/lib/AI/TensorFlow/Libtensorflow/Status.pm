package AI::TensorFlow::Libtensorflow::Status;
# ABSTRACT: Status used for error checking
$AI::TensorFlow::Libtensorflow::Status::VERSION = '0.0.7';
use strict;
use warnings;
use namespace::autoclean;
use AI::TensorFlow::Libtensorflow::Lib;
use FFI::C;

my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
$ffi->mangler(AI::TensorFlow::Libtensorflow::Lib->mangler_default);


# enum TF_Code {{{
# From <tensorflow/c/tf_status.h>
my @_TF_CODE = (
	[ OK                  => 0 ],
	[ CANCELLED           => 1 ],
	[ UNKNOWN             => 2 ],
	[ INVALID_ARGUMENT    => 3 ],
	[ DEADLINE_EXCEEDED   => 4 ],
	[ NOT_FOUND           => 5 ],
	[ ALREADY_EXISTS      => 6 ],
	[ PERMISSION_DENIED   => 7 ],
	[ UNAUTHENTICATED     => 16 ],
	[ RESOURCE_EXHAUSTED  => 8 ],
	[ FAILED_PRECONDITION => 9 ],
	[ ABORTED             => 10 ],
	[ OUT_OF_RANGE        => 11 ],
	[ UNIMPLEMENTED       => 12 ],
	[ INTERNAL            => 13 ],
	[ UNAVAILABLE         => 14 ],
	[ DATA_LOSS           => 15 ],
);

$ffi->load_custom_type('::Enum', 'TF_Code',
	{ rev => 'int', package => __PACKAGE__ },
	@_TF_CODE
);

my %_TF_CODE_INT_TO_NAME = map { reverse @$_ } @_TF_CODE;

#}}}

$ffi->attach( [ 'NewStatus' => 'New' ] => [] => 'TF_Status' );

$ffi->attach( [ 'DeleteStatus' => 'DESTROY' ] => [ 'TF_Status' ], 'void' );

$ffi->attach( 'SetStatus' => [ 'TF_Status', 'TF_Code', 'string' ], 'void' );

$ffi->attach( 'SetPayload' => [ 'TF_Status', 'string', 'string' ], 'void' );

$ffi->attach( 'SetStatusFromIOError' => [ 'TF_Status', 'int', 'string' ],
	'void' );

$ffi->attach( 'GetCode' => [ 'TF_Status' ], 'TF_Code' );

$ffi->attach( 'Message' => [ 'TF_Status' ], 'string' );

use overload
	'""' => \&_op_stringify;

sub _op_stringify {
	$_TF_CODE_INT_TO_NAME{$_[0]->GetCode};
}

sub _data_printer {
	my ($self, $ddp) = @_;
	if( $self->GetCode != AI::TensorFlow::Libtensorflow::Status::OK() ) {
		return sprintf('%s %s %s %s%s%s %s',
			$ddp->maybe_colorize( ref($self), 'class' ),
			$ddp->maybe_colorize( '{', 'brackets' ),
				$ddp->maybe_colorize( $_TF_CODE_INT_TO_NAME{$self->GetCode}, 'escaped' ),
				$ddp->maybe_colorize( '(', 'brackets' ),
					$ddp->maybe_colorize( $self->Message, 'string' ),
				$ddp->maybe_colorize( ')', 'brackets' ),
			$ddp->maybe_colorize( '}', 'brackets' ),
		);
	} else {
		return sprintf('%s %s %s %s',
			$ddp->maybe_colorize( ref($self), 'class' ),
			$ddp->maybe_colorize( '{', 'brackets' ),
				$ddp->maybe_colorize( $_TF_CODE_INT_TO_NAME{$self->GetCode}, 'escaped' ),
			$ddp->maybe_colorize( '}', 'brackets' ),
		);
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::TensorFlow::Libtensorflow::Status - Status used for error checking

=for TF_CAPI_EXPORT TF_CAPI_EXPORT extern TF_Status* TF_NewStatus(void);

=for TF_CAPI_EXPORT TF_CAPI_EXPORT extern void TF_DeleteStatus(TF_Status*);

=for TF_CAPI_EXPORT TF_CAPI_EXPORT extern void TF_SetStatus(TF_Status* s, TF_Code code,
                                        const char* msg);

=begin TF_CAPI_EXPORT

TF_CAPI_EXPORT void TF_SetPayload(TF_Status* s, const char* key,
                                  const char* value);
=end TF_CAPI_EXPORT

=begin TF_CAPI_EXPORT

TF_CAPI_EXPORT extern void TF_SetStatusFromIOError(TF_Status* s, int error_code,
                                                   const char* context);
=end TF_CAPI_EXPORT

=for TF_CAPI_EXPORT TF_CAPI_EXPORT extern TF_Code TF_GetCode(const TF_Status* s);

=for TF_CAPI_EXPORT TF_CAPI_EXPORT extern const char* TF_Message(const TF_Status* s);

=end TF_CAPI_EXPORT

=end TF_CAPI_EXPORT

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Auto-Parallel Technologies, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
