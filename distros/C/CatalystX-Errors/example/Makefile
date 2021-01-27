#
# makefile to help find your way around
#

help:
	@echo ""
	@echo "==> Manage Demo Application"
	@echo "update_cpanlib			Install CPAN libs"		
	@echo "server				Start demo application"
	@echo ""


update_cpanlib:
	@cpanm --verbose --installdeps .

server:
	@perl -Ilib -I ../lib/ ./lib/Example/Server.pm

