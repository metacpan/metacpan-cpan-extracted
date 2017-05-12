use strict;
use Test::More;
use Data::Generator::FromDDL;

my $generator = Data::Generator::FromDDL->new({
    ddl => 'CREATE TABLE users (`id` int NOT NULL AUTO_INCREMENT);',
    parser => 'mysql',
});

my $output;
open my $out_fh, '>', \$output;
$generator->generate(3, $out_fh);

is $output, <<EOL;
INSERT IGNORE INTO `users` (`id`) VALUES (1),(2),(3);
EOL

done_testing;
