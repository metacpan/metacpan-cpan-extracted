
$schema = 
    {
     sql =>
     {
      cid_size => 3,
     },

     class_table => 'Classes',
								  
     classes =>
     [
      Person =>
      {
       fields => {},
         abstract => 1,
      },

      NaturalPerson =>
      {
	   table => 'NP',

	   bases => [ qw( Person ) ],

	   fields =>
	   {
		string =>
		{
		 firstName => { init_default => "bob" },
		 name => undef,
		},

		int => [ qw( age ) ],

		ref =>
		{
		 partner => undef,
		 credit => { aggreg => 1 },
		},

	    rawdate => [ qw( birthDate ) ],
	    rawtime => [ qw( birthTime ) ],
	    rawdatetime => [ qw( birth ) ],
	    dmdatetime => [ qw( incarnation ) ],

		array =>
		{
		 children =>
		 {
		  class => 'NaturalPerson',
		  table => 'a_children',
		  aggreg => 1,
		 },
		 belongings =>
		 {
		  class => 'Item',
		  aggreg => 1,
		  deep_update => 1
		 }
		},

		hash =>
		{
		 h_opinions =>
		 {
		  class => 'Opinion',
		  table => 'h_opinions',
		 }
		},

		iarray =>
		{
		 ia_children =>
		 {
		  class => 'NaturalPerson',
		  coll => 'ia_ref',
		  slot => 'ia_slot',
		  #back => 'ia_parent',
		  aggreg => 1,
		 }
		},

		set =>
		{
		 s_children =>
		 {
		  class => 'NaturalPerson',
		  table => 's_children',
		  aggreg => 1,
		 }
		},

		iset =>
		{
		 is_children =>
		 {
		  class => 'NaturalPerson',
		  coll => 'is_ref',
		  slot => 'is_slot',
		  #back => 'is_parent',
		  aggreg => 1,
		 }
		},

		flat_array => [ qw( interests ) ],

		flat_hash => [ qw( opinions ) ],

		perl_dump => [ qw( brains ) ],
	   },
       methods => {
		   set_brains => sub {
		       my $self = shift;
		       my $braynez = shift;
		       $braynez .= " bork bork bork";
		       $self->{brains} = $braynez;
		   },

		  }
      },

	Opinion =>
	{
	 fields =>
	 {
	  string => [ qw( statement ) ],
	 },
	},

	LegalPerson =>
	{
	 bases => [ qw( Person ) ],

	 fields =>
	 {
	  string =>
	  [ qw( name ) ],

	  ref =>
	  {		
	   manager => { null => 1 }
	  },
	 },
	},

	EcologicalRisk =>
	{
	 abstract => 1,

	 fields =>
	 {
	  int => [ qw( curies ) ],
	 },
	},
   
	NuclearPlant =>
	{
	 bases => [ qw( LegalPerson EcologicalRisk ) ],

	 fields =>
	 {
	  array =>
	  {
	   employees =>
	   {
		class => 'NaturalPerson',
		table => 'employees'
	   }
	  },
	 },
	},

	Credit =>
	{
	 fields =>
	 {
	  #int => { limit => { col => 'theLimit' } },
	  int => { limit => 'theLimit' },
	 }
	},

        Item =>
        {
	 fields =>
	 {
	  string => [ qw(name) ],
	  ref =>
	  {
	   owner => { deep_update => 1 }
	  }
	 }
	},

   ] };
