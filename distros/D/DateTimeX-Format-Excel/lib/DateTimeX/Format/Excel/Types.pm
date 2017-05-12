package DateTimeX::Format::Excel::Types;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.14.0");
use	5.010;
use strict;
use warnings;
use Type::Utils -all;
use Type::Library 1.000
	-base,
	-declare => qw(
		DateTimeHash
		DateTimeInstance
		HashToDateTime
		ExcelEpoch
		SystemName
	);
use Types::Standard qw(
		Str Dict Optional InstanceOf Int Num is_Num
	);
my $try_xs =
		exists($ENV{PERL_TYPE_TINY_XS}) ? !!$ENV{PERL_TYPE_TINY_XS} :
		exists($ENV{PERL_ONLY})         ?  !$ENV{PERL_ONLY} :
		1;
if( $try_xs and exists $INC{'Type/Tiny/XS.pm'} ){
	eval "use Type::Tiny::XS 0.010";
	if( $@ ){
		die "You have loaded Type::Tiny::XS but versions prior to 0.010 will cause this module to fail";
	}
}
use DateTime;
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for DateTimeX-Format-Excel-Types ...
}

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9



#########1 Type Library       3#########4#########5#########6#########7#########8#########9

declare DateTimeHash,
      as Dict[
         year       => Int,
         month      => Optional[ Int ],
         day        => Optional[ Int ],
         hour       => Optional[ Int ],
         minute     => Optional[ Int ],
         second     => Optional[ Int ],
         nanosecond => Optional[ Int ],
         time_zone  => Optional[ Str ],
      ];

declare DateTimeInstance,
	as InstanceOf[ "DateTime" ];

declare_coercion HashToDateTime,
	to_type DateTimeInstance,
	from DateTimeHash,
	q{ DateTime->new( $_ ) };

declare ExcelEpoch,
	as Num,
	where{ $_ >= 0 },
	message{
		( !defined $_ ) 	? "No value passed" :
		( !is_Num( $_ ) )	? "-$_- is not a Number" :
							  "-$_- is less than 0"
	};

declare SystemName,
	as Str,
	where{ $_ =~ /^(win_excel|apple_excel)$/ };

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

DateTimeX::Format::Excel::Types::Types - A Type::Tiny Excel DateTime type library

=head1 DESCRIPTION

This is a type library for L<DateTimeX::Format::Excel> It doesn't really have good context
outside of that.  It is built on L<Type::Tiny>.

=head2 L<Caveat utilitor|http://en.wiktionary.org/wiki/Appendix:List_of_Latin_phrases_(A%E2%80%93E)#C>

All type tests included with this package are considered to be the fixed definition of
the types.  Any definition not included in the testing is considered flexible.

This module uses L<Type::Tiny> which can, in the background, use L<Type::Tiny::XS>.
While in general this is a good thing you will need to make sure that
Type::Tiny::XS is version 0.010 or newer since the older ones didn't support the
'Optional' method.

=head2 Types

=head3 DateTimeHash

=over

B<Definition:> How to know if a hash meets the DateTime hash requirements

B<Range>

	Dict[
		year       => Int,
		month      => Optional[ Int ],
		day        => Optional[ Int ],
		hour       => Optional[ Int ],
		minute     => Optional[ Int ],
		second     => Optional[ Int ],
		nanosecond => Optional[ Int ],
		time_zone  => Optional[ Str ],
	]

=back

=head3 DateTimeInstance

=over

B<Definition:> An instance of a L<DateTime> object

=back

=head3 ExcelEpoch

=over

B<Definition:> Numbers used by Microsoft Excel to descibe a point in time.

B<Range> All numbers greater than or equal to 0

=back

=head3 SystemName

=over

B<Definition:> labels for the different Excel calculation rules and epoch start.

B<Range> win_excel|apple_excel

=back

=head2 Named Coercions

=head3 HashToDateTime

=over

B<Accepts: > A DateTimeHash

B<Returns: > A L<DateTime> instance

B<Conversion Method: > DateTime->new( $DateTimeHash );

=back

=head1 SUPPORT

=over

L<github DateTimeX::Format::Excel/issues|https://github.com/jandrew/DateTimeX-Format-Excel/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<yet|/SUPPORT>

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<version>

L<DateTime>

L<Type::Utils>

L<Type::Library>

L<Types::Standard>

=back

=head1 SEE ALSO

=over

L<DateTime::Format::Excel>

L<Smart::Comments> - Turned on with $ENV{ Smart_Comments }

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
