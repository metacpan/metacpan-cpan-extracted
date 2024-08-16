use strict;
use warnings;

package T::Database;

use Test::Most;
use Data::Dumper::Concise;
use Capture::Tiny 'capture_stdout', 'capture_stderr', 'capture';
use DBIx::Squirrel;
use T::Constants ':all';


BEGIN {
	require Exporter;
	@T::Database::ISA         = ( 'Exporter' );
	%T::Database::EXPORT_TAGS = (
		all => [
			@{ $T::Constants::EXPORT_TAGS{ all } },
			(
			  'diag_result',
			  'diag_val',
			  'dump_result',
			  'dump_val',
			  'result',
			),
		],
	);
	@T::Database::EXPORT_OK = @{ $T::Database::EXPORT_TAGS{ all } };
}


sub connect
{
	DBIx::Squirrel->connect( @T_DB_CONNECT_ARGS );
}


sub diag_result
{
	diag result( @_ );
}


sub result
{
	my ( $sth ) = @_;
	my ( $summary, @rows ) = do {
		my @res = split /\n/, capture { $sth->dump_results };
		( pop @res, @res );
	};
	return join "\n", (
		'',
		'Statement',
		'---------',
		$sth->{ Statement }, '',
		do {
			if ( %{ $sth->{ ParamValues } } ) {
				(
				  'Parameters',
				  '----------',
				  Dumper( $sth->{ ParamValues } ),
				);
			} else {
				();
			}
		},
		do {
			if ( @rows ) {
				(
				  'Result (' . $summary . ')',
				  '--------' . ( '-' x ( 1 + length( $summary ) ) ),
				  @rows,
				);
			} else {
				();
			}
		},
		"\n",
	);
}


sub dump_result
{
	print STDERR result( @_ );
}


sub diag_val
{
	diag Dumper( @_ );
}


sub dump_val
{
	print STDERR Dumper( @_ );
}

1;
