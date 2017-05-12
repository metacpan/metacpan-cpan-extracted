use Test::More tests => 20;

use File::Spec::Functions qw(catfile);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $class = 'ConfigReader::Simple';
my $method = 'exists';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my @Directives = qw( Test1 Test2 Test3 Test4 );

my $config = $class->new( catfile( qw(t example.config) ), \@Directives );
isa_ok( $config, $class );
can_ok( $config, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# these directives should be okay
{
foreach my $directive ( @Directives )
	{
	ok( $config->$method( $directive ), "Directive [$directive] exists" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# these directives should not be okay
{
my @Directives = qw( Test5 exists blah get );

foreach my $directive ( @Directives )
	{
	ok( ! $config->$method( $directive ), "$method fails for $directive");
	ok( ! $config->get( $directive ),     "get( $directive ) fails"     );
	ok( ! $config->$directive,            "->$method fails"             );
	}
}
