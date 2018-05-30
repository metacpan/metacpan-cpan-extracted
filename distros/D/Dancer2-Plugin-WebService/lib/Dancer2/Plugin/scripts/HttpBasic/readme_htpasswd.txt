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

	touch               /etc/WebService/htpasswd.{users,admins}
	chown george:george /etc/WebService/htpasswd.{users,admins}

add user        : htpasswd -b    /etc/WebService/htpasswd.admins root  password
                  htpasswd -b    /etc/WebService/htpasswd.users  kojak g00dl0rd
verify password : htpasswd -b -v /etc/WebService/htpasswd.admins root  password
delete user     : htpasswd -D    /etc/WebService/htpasswd.admins root
