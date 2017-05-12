#!/usr/local/bin/perl

use lib '.','..';

use Stone;

my $stone = Stone->new(name=>'fred',
                       age=>30,
		       address=>{
				 Mail=>{
					street=>'19 Gravel Path',
					town=>'Bedrock',
					ZIP=>'12345'
				       },
				 Electronic=>{
					      fax=>'111,1111',
					      email=>'foo@bar.com'
					     }
				},
		       phone=>{
			       day=>[[qw/xxxx-xxxx yyy-yyyy/],
				     [qw/111-1111 333-3333/]
				     ],
			       eve=>'222-2222'
			      },
		       friends=>[qw/amy agnes wendy joe/],
		       preferences=>{
				     candy=>[qw/sweet chocolate caramel/],
				     sports=>[qw/basketball baseball/],
				     dining=>[qw/ethnic/]
				    }
		      );
print $stone->asTable;

