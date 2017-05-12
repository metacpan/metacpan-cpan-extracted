
use strict ;
use warnings ;

my $DESTINATION_DIRECTORY = '/home/nadim/Desktop/http_share/plog' ;
my $PAGE = 'http://khemir.net/http_share/plog/plog.html' ;
my $BLOG = 'plog' ;
my $HOME = $ENV{HOME} ;

<<`EOC` ;
cd $HOME/.plog

cp -R $HOME/.plog/configuration_template/ $HOME/.plog/$BLOG
cd $HOME/.plog/$BLOG

mkdir blog_entries
cd blog_entries
git init

sed -i -e 's#ENTRY_DIRECTORY#$HOME/.$BLOG/$BLOG/blog_entries#' $HOME/.plog/$BLOG/config.pl
sed -i -e 's#PAGE#$PAGE#' $HOME/.plog/$BLOG/config.pl
sed -i -e 's#DESTINATION_DIRECTORY#$DESTINATION_DIRECTORY#' $HOME/.plog/$BLOG/config.pl

sed -i -e 's#PLOG_ROOT_DIRECTORY#$HOME/.$BLOG/#' $HOME/.plog/config.pl
sed -i -e 's/DEFAULT_BLOG/$BLOG/' $HOME/.plog/config.pl

cp ../entry_template.pod first_entry.pod
git add first_entry.pod
git commit -a -m 'ADDED: first entry'

plog generate --temporary_directory tmp
firefox tmp/plog.html
EOC
