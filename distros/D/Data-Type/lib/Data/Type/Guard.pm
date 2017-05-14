
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Guard;

	use Carp;

	use Exporter;

	use subs qw(typ untyp istyp);

	our %EXPORT_TAGS = 
        ( 
	  'all' => [qw(valid_object)],
	);
	
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	
	our @EXPORT = ();

	Class::Maker::class
	{
		isa => [qw( Exporter )],

		public =>
		{
			array => [qw( allow )],

			hash => [qw( tests )],
		},
	};

           # Control whether we take the Class::Maker reflection information ( the types => {} field ) for the 
           # testing procedure.

        our $AUTO_DETECT = 0; 

	sub inspect : method
	{
		my $this = shift;

		my $object = shift;

		my $decision;

		if( @{ $this->allow } > 0 )
		{			
			my %t;
	
			@t{ $this->allow } = 1;

			unless( exists $t{ ref( $object ) } )
			{
				carp "Guard is selective and only accepts ", join ', ', $this->allow if $Data::Type::DEBUG;

				return 0;
			}
		}

		Data::Type::try
		{
			Data::Type::Guard::valid_object( { $this->tests }, $object );

			$decision = 1;
		}
		catch Data::Type::Exception Data::Type::with
		{
			$decision = 0;
		};
	
	return $decision;
	}

		# valid a collection of types against an object

	sub valid_object
	{
		my $rules = shift;

		my @objects = @_;

		my $m;

		Data::Type::try
		{
			foreach my $obj ( @objects )
			{
			    if( $Data::Type::Guard::AUTO_DETECT )
			    {
				if( my $cm_object_definition = Class::Maker::Reflection::_get_definition( $object ) )
				{	
				    if( exists $cm_object_definition->{types} )
				    {	
					$rules = $cm_object_definition->{types};
				    }		
				}
			    }
				foreach ( Data::Type::iter $rules )
				{
					my ( $m, $t ) = ( $_->KEY(), $_->VALUE() );

					if( ref( $t ) eq 'ARRAY' )
					{
						Data::Type::valid( $obj->$m , $_ ) for  @{ $t };
					}
					elsif( ref( $t ) eq 'CODE' )
					{
						throw Data::Type::Exception( text => 'valid_object nok with '.$m.' for object via CODEREF' ) unless $t->( $obj->$m );
					}
					else
					{
						Data::Type::valid( $obj->$m , $t );
					}
				}
			}
		}
		catch Data::Type::Exception Data::Type::with
		{
			my $e = shift;

			throw $e;
		};
	}

1;

__END__

=head1 NAME

Data::Type::Guard - inspects members of foreign objects

=head1 SYNOPSIS

  my $dtg = Data::Type::Guard->new
  (
    allow => [ 'Human', 'Others' ],		# blessed objects of that type

    tests =>
    {
      email =>     STD::EMAIL( 1 ), # mxcheck ON ! see Email::Valid

      firstname => STD::WORD,

      social_id => [ STD::NUM, STD::VARCHAR( 10 ) ],

      contacts =>   sub { my %args = @_; exists $args{lucy} },
    }
  );

  die "object is rejected" unless $dtg->inspect( $h );

    # compact version

  valid_object { email => STD::EMAIL( 1 ), firstname => STD::WORD }, $object_a, $object_b;

=head1 INTRODUCTION

This class inspects others objects member return-values for a specific datatype.

=head1 API

=head2 CONSTRUCTOR

 my $dtg = Data::Type::Guard->new( allow => $aref, tests => $href )

=head3 allow => $aref

If is set then the C<inspect> function below will return C<0> if the object is not a reference of the requested type. If empty, isn't selective for special references (  HASH, ARRAY, "CUSTOM", .. ). 

=head3 tests => $href

Keys are the members names (anything that can be called via the $o->member syntax) and the type(s) as value. When a member should match multple types, they should be contained in an array reference ( i.e. 'fon' => [ qw(NUM TELEPHONE) ] ). Instead of types a reference to a sub is allowed, while it must return true if it matches (see L<valid_object()|/"valid_object( { member => TYPE, .. }, @objects )">).

=head2 METHODS

=head3 $dtg->inspect( $blessed )

Accepts a blessed reference as a parameter. It returns C<0> if a guard test or type constrain will fail, otherwise C<1>.

[Note] A more appropriate report on failure is planned.

=head2 FUNCTIONS

=head3 valid_object( { member => TYPE, .. }, @objects )

Valids members of objects against multiple 'types' or code reference. Any C<$object> must have an accessor function to its method (same as the key given in the C<member> C<$href>). See L<Data::Type::Guard> for oo-interface for that. 

  my $car = Car->new( speed => 300, year => '2000', owner_firstname => 'micheal' );

  valid_object( { year => DATE( 'YEAR' ), owner_firstname => VARCHAR(20), speed => INT }, $car ) or die;

=head1 AUTO DETECTION

B<$Data::Type::Guard::AUTO_DETECT> controls if information from the reflection of an object is superseeding the B<tests =>> parameter. Visit L<Class::Maker> reflection manual ( for the C<types => {}> field ). Example:

 use Data::Type qw(:all);

 use Data::Type::Guard;

 use Class::Maker qw(class);

 class 'My::Car',
 {
    public =>
    {
       string => [qw( name manufactorer )],

       int => [qw( serial )],
    },
    
    types =>
    {
       name => STD::WORD,
       
       serial => STD::NUM,
    },
 };

   my $dtg = Data::Type::Guard->new();

   die "My::Car isnt correctly initialized" unless $dtg->inspect( My::Car->new( serial => 'aaaaaa', name => '111' ) );

[Note] This feature is available after L<Class::Maker> '0.5.18', but this is still an undocumented yet.

=head1 EXPORT

None per default.

C<valid_object>.

B<':all'> loads qw(valid_object)


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

