#!/usr/bin/perl
use strict;
use Apache::Session::Memorycached;
use Data::Dumper;
use Cache::Memcached;
my $serveur = shift;
my $option; 
my $session_id;
my @command = ("-s","-m","-d","-i","-TAG","-show","-modify","-delete","-info") ;
 
if (index($serveur,"-") != -1){

$option = $serveur;
$serveur = "localhost:11211";
}else{
$option = shift;
}
my $contenu;

if ($option eq "-s" or $option eq "-show"){
	$session_id = shift;	
	my $memd= new Cache::Memcached  { 'servers' => [$serveur]};
	my $hashref = $memd->get_multi();
	$contenu = Dumper($hashref);
	print ("$contenu\n");	
	my %session;
	
	tie %session, 'Apache::Session::Memorycached', $session_id, { 'servers' => [$serveur]} ;
	
	$contenu = Dumper(%session);
	if (keys(%session)==0){
		print "Aucune valeures pour l'entree [ $session_id ]\n";	
	}else{
		print "Contenu du memcached pour l'entree [ $session_id ]\n";
		print ("$contenu\n");
	}
	untie %session;
	exit;
}

if ($option eq "-m" or $option eq "-modify"){
	$session_id = shift;
	my $key = shift;
	my $value = shift;
	my %session;

	tie %session, 'Apache::Session::Memorycached', $session_id, { 'servers' => [$serveur]} ; 

	if (keys(%session)==0){
		print "Aucune valeures pour l'entree [ $session_id ]\n";
		exit;
	}
	print "Contenu du memcached pour l'entree[ $session_id ] avant modification : \n";
	$contenu = Dumper(%session);
	print ("$contenu\n");
	print "\n";
	my %Session;
	tie %Session, 'Apache::Session::Memorycached', undef, { 'servers' => [$serveur]};
                foreach (keys %session){
			if ($_ ne $key){
                        	$Session{$_} = $session{$_} if $session{$_} ;
        		}else{
				$Session{$_} = $value;
			}
		}

	my $cont = Dumper(%Session);
        print "Contenu du memcached pour l'entrée[ $session_id ] apres modification : \n";
	print ("$cont\n");
	print "\n";
	untie %Session;
	exit;
}
  

if($option eq "-d" or $option eq "-delete"){
	$session_id = shift;
	my $cle = shift;
	my %session;

	tie %session, 'Apache::Session::Memorycached', $session_id, { 'servers' => [$serveur]} ;
	
	$contenu = Dumper(%session);
	if (keys(%session)==0){
                print "Aucune valeures pour l'entree [ $session_id ]\n";
                exit;
        }

	print ("$contenu\n");
	print "\n";
	if (!defined($cle)){
		my $memd= new Cache::Memcached  { 'servers' => [$serveur]};

		my $result = $memd->delete($session_id);
		if ($result){
			print "L'entree [ $session_id ] a ete supprime du serveur \n";
		}else{
			print "L'entree [ $session_id ] n\'a pu etre supprime du serveur \n";
		}
	}else{
		my %Session;
        	tie %Session, 'Apache::Session::Memorycached', undef, { 'servers' => [$serveur]};
                foreach (keys %session){
                        if ($_ ne $cle){
                                $Session{$_} = $session{$_} if $session{$_} ;
                        }
                }

        my $cont = Dumper(%Session);
        print "Contenu du memcached pour l'entrée[ $session_id ] apres modification : \n";
        print ("$cont\n");
        print "\n";
        untie %Session;
	}
        exit;

	exit;

}

if($option eq "-i" or $option eq "-info"){
        
	my $memd= new Cache::Memcached  { 'servers' => [$serveur] };
	my $tag = shift;
	if (!defined($tag)){
		my $result = $memd->stats();
		my $pid = $result->{hosts}->{$serveur}->{misc}->{pid};
		my $taille = $result->{hosts}->{$serveur}->{malloc}->{arena_size};
		print "Pid    =>   $pid
";
my $clef;
my $valeur;

while (($clef, $valeur) = each(%{$result->{total}})) {
print "
$clef  =>  $valeur\n";
}
	}else{			
		my $result = $memd->stats($tag);
       		$contenu = Dumper($result);
	 	print ("$contenu\n");
        	print "\n";
}
exit;
}

if($option eq "-TAG"){
print "
List of Tags : 

misc      =>   The stats returned by a 'stats' command: pid, uptime, version, bytes, get_hits, etc.

malloc    =>   The stats returned by a 'stats malloc': total_alloc, arena_size, etc.

sizes     =>   The stats returned by a 'stats sizes'.

self      =>   The stats for the \$memd object itself (a copy of \$memd->{'stats'}).

maps      =>   The stats returned by a 'stats maps'.

cachedump =>   The stats returned by a 'stats cachedump'.

slabs     =>   The stats returned by a 'stats slabs'.

items     =>   The stats returned by a 'stats items'.\n";
exit;
}
print "Usage :  ./memd.pl [serveur::port] -s (-show)  [id]
                                   -d (-delete) [id]
                                   -m (-modify) [id] [Champs] [valeur]
                                   -a (-add) [id] [Champs] [valeur]
                                   -i (-info) [TAG]
Launch \"./memd.pl -TAG\" to get the list of TAG
\n";





