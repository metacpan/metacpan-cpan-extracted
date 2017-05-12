This is a typical external authorization utility (written in Perl)
it waits for the following three arguments

   hex packed username
   hex packed password
   comma delimitted groups that the user should be member at least to one of them

It will perform native Linux authentication
and tt will print at screen the following three lines

   1 for succesfull login   or   0 for a failed login
   A message, usually the error if the login was failed
   A comma delimited group list, that the user is member (from the passed ones)


If a non root e.g george try to run this utility he will get an error, except
he is defined at sudo file e.g.


chmod u+wrx     /usr/share/perl5/site_perl/Dancer2/Plugin/scripts/LinuxOS/AuthUser.pl
visudo  # or vi /etc/sudoers



	# Defaults    requiretty

	# let user george check linux login
	george ALL=NOPASSWD: /usr/share/perl5/site_perl/Dancer2/Plugin/scripts/LinuxOS/AuthUser.pl



George Mpouras
george.mpouras@yandex.com
7 June 2016
Athens Greece
