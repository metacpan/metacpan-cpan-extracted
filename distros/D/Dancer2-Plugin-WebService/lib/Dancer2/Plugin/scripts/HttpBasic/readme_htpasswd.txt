install htpasswd at CentOS

	yum -y install httpd-tools

If you have not install Apache, install only the htpasswd at archlinux

 	su -l aur
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/apache-tools.tar.gz
	tar -xvzf apache-tools.tar.gz
	find      apache-tools -type f -exec chmod 664 '{}' \;
	find      apache-tools -type d -exec chmod 775 '{}' \;
	cd        apache-tools
	makepkg -si
	cd ..
	rm -rf apache-tools

Create two different user files, for common users and administrators; also create two users.
Assuming george is the user that runs the service
and the config files are inside the folder /opt/WebService/

	touch               /opt/WebService/htpasswd.{users,admins}
	chown george:george /opt/WebService/htpasswd.{users,admins}

add user        : htpasswd -b    /opt/WebService/htpasswd.admins root  password
	          htpasswd -b    /opt/WebService/htpasswd.users  kojak g00dl0rd
verify password : htpasswd -b -v /opt/WebService/htpasswd.admins root  password
delete user     : htpasswd -D    /opt/WebService/htpasswd.admins root