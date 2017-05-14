package DBIx::XML::DataLoader::IsDefined;


use strict;
use warnings;

#############
sub new{
########
my $self=shift;
bless \$self;

######
}# end sub new
#############

sub verify{
if((scalar @_) < 2){return undef;}
my $self = shift;
my $variable=shift;

{no warnings; # warning are turned off here because we are playing with a var that might not be declared

my $cnt=split //, $variable;
if($cnt == 0){return undef;}
}
return $variable;

}
1;




__END__


=head1 NAME

        DBIx::XML::DataLoader::IsDefined


=head1 SYNOPSIS

        use DBIx::XML::DataLoader::IsDefined;
	
	my $test_a=0;
	my $test_b="";
	if(defined $test_a){print "TEST A:",  $test_a, "\n";}	
	if(defined $test_b){print "TEST B:",  $test_b, "\n";}	

	my $value_a=DBIx::XML::DataLoader::IsDefined->verify($test_a);
	my $value_b=DBIx::XML::DataLoader::IsDefined->verify($test_b);
	if(defined $value_a){print "VALUE TEST A:",  $value_a, "\n";}	
	if(defined $value_b){print "VALUE TEST B:",  $value_b, "\n";}	

=for text  or

=for man  or

=for html <b>or</b>

	use DBIx::XML::DataLoader::IsDefined;

        my $d=DBIx::XML::DataLoader::IsDefined->new();
        my $test_a=0;
        my $test_b="";
        if(defined $test_a){print "TEST A:",  $test_a, "\n";}
        if(defined $test_b){print "TEST B:",  $test_b, "\n";}

        my $value_a=$d->verify($test_a);
        my $value_b=$d->verify($test_b);
        if(defined $value_a){print "VALUE TEST A:",  $value_a, "\n";}
        if(defined $value_b){print "VALUE TEST B:",  $value_b, "\n";}


=head2 The results

	TEST A:0
	TEST B:
	VALUE TEST A:0


=head1 DESCRIPTION

        This module is used primarily inside DBIx::XML::DataLoader. It checks to
	see if a node value is the number zero or if the variable is 
	defined but empty. If the variable is defined but empty then undef is 
	returned by the module.



=for html
<p><hr><p>

