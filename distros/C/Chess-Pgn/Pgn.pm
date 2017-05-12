package Chess::Pgn;

require 5.004;
#use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';


           my $LINE ="";
           my $FLAG=1;
           my $GAME=0;


	 sub _init {
		 my $self=shift;
           $self->{Event}="";
           $self->{Site}="";
           $self->{Date}="";
           $self->{Round}="";
           $self->{White}="";
           $self->{Black}="";
           $self->{Result}="";
           $self->{ECO}="";
           $self->{WhiteElo}="";
           $self->{BlackElo}="";
           $self->{PlyCount}="";
           $self->{Game}="";
           $FLAG=1;
           $GAME=0;
		 }

           sub new {
           my $this= shift ; 
           my $class= ref($this) || $this ;
           my $file=shift;
           my $self=bless {},$class;
           $self->_init();
           if (defined $file) 
            {
             $self->{file} = $file;
             $self->open($file, -umod => $args{-umod}) or return undef;
             }
           return ($self);
           }
		
		 sub game
           {
              my $self=shift; 
              if (@_) {$self{Game}=shift; }
              return $self->{Game} 	 
           }
  
           sub blackelo
           {
            my $self=shift; 
              if (@_) {$self{BlackElo}=shift; }
              return $self->{BlackElo} 	 	
           }         
	
	      sub plycount
           {
            my $self=shift; 
              if (@_) {$self{PlyCount}=shift; }
              return $self->{PlyCount} 	 	
           }         
	  
 
           sub whiteelo
           {
            my $self=shift; 
              if (@_) {$self{WhiteElo}=shift; }
              return $self->{WhiteElo} 	 	
           }         
		
		 sub eco
           {
              my $self=shift; 
              if (@_) {$self{ECO}=shift; }
              return $self->{ECO} 	 
           }
           
		
		 sub result
           {
              my $self=shift; 
              if (@_) {$self{Result}=shift; }
              return $self->{Result} 	 
           }
           
		 sub black
           {
              my $self=shift; 
              if (@_) {$self{Black}=shift; }
              return $self->{Black} 	 
           }
           
		 sub white
           {
              my $self=shift; 
              if (@_) {$self{White}=shift; }
              return $self->{White} 	 
           }
           
		
		 sub round
           {
              my $self=shift; 
              if (@_) {$self{Round}=shift; }
              return $self->{Round} 	 
           }
           
		 sub date
           {
              my $self=shift; 
              if (@_) {$self{Date}=shift; }
              return $self->{Date} 	 
           }
           
		
		 sub site
           {
              my $self=shift; 
              if (@_) {$self{Site}=shift; }
              return $self->{Site} 	 
           }
           
           sub event
           {
              my $self=shift; 
              if (@_) {$self{Event}=shift; }
              return $self->{Event} 	 
           }

           sub open      
           {
      	 my ($self, $file, %args) = @_;
            if (defined $file)  { $self->{file} = $file;}
            else { $file = $self->{file};  }

            open FICPGN, "<$file" or return 0;
            $LINE=<FICPGN>;
            $LINE=~s/\r//;
		  return 1 ;            
           } 

		 sub quit
		 {
		  close (FICPGN);
		 }
		 
		 sub PrintAll
		 {
		  my $self=shift;
		  my $return ;
		  my @Keys=(Event,Site,Date,Round,White,Black,Result,ECO,WhiteElo,BlackElo,PlyCount);
 		 foreach my $i ( @Keys )
 		   {
 		   	$return.="[$i \"".$self->{$i}."\"]\n";
 		   }
 		 $return .="\n";
 		 $return.=$self->{Game};
            $return .="\n";
		 }
		            
		 sub ReadGame
		 {
		  my $self=shift;
		  my $continue=1;
		  $self->_init();
		  do
		   {
		    if ( $continue == 2 ) { $continue = 0 } 
		    if ( $LINE =~/\[(.*)\]/ ) 
		     {
		      my $line=$1;
		      my ($key,$val,$junk)=split(/"/,$line);
		      $key=~s/ $//g,
		      $self->{$key}=$val;
		      $GAME=0;
		     }
		    elsif ( $LINE !~/^$/)
		     {
		        $self->{Game}.=$LINE; 
		        $GAME=1;
		     }
		    elsif ( $GAME == 1 ) 
		     {
		        $FLAG=0;  
		     }
		    $LINE=<FICPGN>;
		    if ( eof(FICPGN) && $continue == 1  ) { $continue = 2  }
              $LINE=~s/\r//;
		   }
		  while ( $FLAG==1 );
		  return ( $continue ) ;
		 }





1;
__END__


=head1 NAME

Chess::Pgn - Perl extension for manipulation of chess PGN format. PGN is for 
Portable Game Notation and follow the I<Portable Game Notation Specification and Implementation Guide>
revised 1994.03.12. You can find it at L<http://members.nbci.com/sghudson/standard.txt>.

The goal of this module is not to play chess but to help to manipulate PGN File. 

A PGN file is like this : 

 [Event "?"]
 [Site "?"]
 [Date "????.??.??"]
 [Round "?"]
 [White "Greco"]
 [Black "NN"]
 [Result "1-0"]
 [ECO "C57"]
 [WhiteElo "2010"]
 [BlackElo "1620"]
 [PlyCount "17"]


 1.e4 e5 2.Nf3 Nc6 3.Bc4 Nf6 4.Ng5 d5 5.exd5 Nxd5 6.Nxf7 Kxf7 7.Qf3+ Ke6
 8.Nc3 Ne7 9.O-O c6 10.Re1 Bd7 11.d4 Kd6 12.Rxe5 Ng6 13.Nxd5 Nxe5
 14.dxe5+ Kc5 15.Qa3+ Kxc4 16.Qd3+ Kc5 17.b4# 1-0

 [Event "?"]
 [Site "corr CS ch 22 (FS"]
 [Date "????.??.??"]
 [Round "12.0"]
 [White "Rosenzweig V"]
 [Black "Necesany Z"]
 [Result "1/2-1/2"]
 [ECO "C55"]
 [WhiteElo "2410"]
 [BlackElo "2620"]
 [PlyCount "22"]

 1.e4 e5 2.Nf3 Nc6 3.Bc4 Nf6 4.O-O Be7 5.Nc3 Nxe4 6.Nxe4 d5 7.d4 dxc4
 8.d5 Nd4 9.Nxd4 Qxd5 10.Nf3 Qxe4 11.Re1 Qc6 12.Nxe5 Qf6 13.Bd2 O-O
 14.Bc3 Bc5 15.Re2 Qf5 16.Qd5 Bd6 17.Rae1 Be6 18.Qxb7 f6 19.Nc6 Bd5
 20.Rd2 Bxg2 21.Rxd6 Bxc6 22.Rxc6 Qg4+ 1/2-1/2


With Chess:Pgn you will find a game by $game->date or $game->game. 
For our last example we will have 

 $game->date : "????.??.??"
 $game->game : "1.e4 e5 2.Nf3 Nc6 3.Bc4 Nf6 4.Ng5 d5 5.exd5 Nxd5 6.Nxf7 Kxf7 7.Qf3+ Ke6
 8.Nc3 Ne7 9.O-O c6 10.Re1 Bd7 11.d4 Kd6 12.Rxe5 Ng6 13.Nxd5 Nxe5
 14.dxe5+ Kc5 15.Qa3+ Kxc4 16.Qd3+ Kc5 17.b4# 1-0"
 

The module provide a good set of tools to modify PGN File but you will have to make yourself the while :)


=head1 SYNOPSIS

 use Chess::Pgn;
 $p = new Chess::Pgn("2KTSDEF.PGN" ) || die "2KTSDEF.PGN not found";
 while ( $p->ReadGame ) 
  {
   print $p->white ,"<=>",$p->black, "\n";
  }
 $p->quit();
 
 $p->white(Kouatly);
 $p->black(Kasparov);


=head1 DESCRIPTION

=over 1 

=item new

 $p= new Chess::Pgn ("name")
 
open the file I<name> and if it doesn't exist return undef.


=item ReadGame

 $p->ReadGame 
 
This method read just one game and return undef at the end of file. You must use methods to read the game.

=item quit 

 $p->quit
 
Close the PGN file 

=item Basic methods

 site, date, round, white, black, result, eco, whiteelo, blackelo, plycount, game : 
 
return the value of the current game.

 $p->black return Greco 
 
=item set a value 

You can change a value if you put a argument to the method. 

For example : 

 $p->black("Gilles Maire") 
 
will change the value of the black opponent. But just in memory ! You will need to write of file to save it.


=item variable 

You can access to method value bye the hash 
  
  $p->{Event}, $p->{Site} , $p->{Date} ,p->{Round},$p->{White},$p->{Black},
  $p->{Result}, $p->{ECO},$p->{Game}; $p->{WhiteElo}, $p{BlackElo}, $p->{PlyCount}

=item All in One method

  $p->PrintAll;

return in a string all the lines concerning the current game. You can of course modify
 some values before call this method.  


=back 


=head2 EXPORT

None by default.

=head1 AUTHOR

Gilles Maire 

Gilles.Maire@ungi.net 

=head1 SEE ALSO

perl(1).

=cut
