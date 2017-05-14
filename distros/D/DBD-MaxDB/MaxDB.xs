/*!
  @file           MaxDB.xs
  @author         MarcoP
  @ingroup        dbd::MaxDB
  @brief          

\if EMIT_LICENCE

    ========== licence begin  PERL_STANDARD
    Copyright (c) 2001-2004 SAP AG

    This program is free software; you can redistribute it and/or
    modify it under the terms of either the Artistic License, as
    specified in the Perl README file or the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
    ========== licence end


\endif
*/
#include "dbdimp.h"

#ifndef WIN32
#define UNIX UNIX
#endif

#ifdef __hpux
#define DONT_DECLARE_STD
#endif

/*
 * instinfo.c
 */
#ifdef UNIX
#include <pwd.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>
#endif

struct info {
	char *key;
	char *val;
	struct info *next;
};

typedef struct info info_t;

static info_t *
infofree (info_t *ptr) {
	info_t *next;

	for (;;) {
		if (ptr == 0)
			break;

		next = ptr->next;

		if (strcmp (ptr->key, "db") == 0) {
			if (ptr->val != 0)
				infofree ((info_t *)(ptr->val));
		} else { 
			if (ptr->val != 0)
				Safefree (ptr->val);
		}

		if (ptr->key != 0)
			Safefree (ptr->key);

		Safefree (ptr);
		ptr = next;
	}

	return 0;
}

static info_t *
infoadd (info_t *their, const char *key, char *val) {
	info_t *our;
	info_t *curr;

	Newz(101, our, 1, info_t);
	if (our == 0) {
		infofree (their);
		return 0;
	}

	New(101, our->key, strlen (key) + 1, char);
	if (our->key == 0) {
		Safefree (our);
		infofree (their);
		return 0;
	}

	strcpy (our->key, key);
	our->val = val;

	if (their == 0)
		return (our);

	for (curr = their; curr->next != 0; curr = curr->next);
	curr->next = our;
	return (their);
}

#ifdef UNIX
static const char sapdb_keyname[] = "/usr/spool/sql";
static const char sapdb_ininame[] = "ini/SAP_DBTech.ini";

static const char sapdb_globals_filename[]   = "/etc/opt/sdb";
static const char sapdb_databases_filename[] = "config/Databases.ini";

static char *
readline (int fd) {
	char *buff;
	int len;
	int want;
	int got;
	int pos;
	char *ptr;
	int buffsize;
	int offset;

	offset = 0;
	buffsize = 80;
  New (101, buff, buffsize+1, char);
	if (buff == 0)
		return 0;

	pos = lseek (fd, 0, SEEK_CUR);
	buff[0] = '\0';

	for (;;) {
		want = buffsize - offset;
		got = read (fd, buff + offset, want);

		if (got == 0 && buff[0] == '\0') {
			Safefree (buff);
			return 0;
		}

		if (got == 0)
			break;

		ptr = strchr (buff, '\n');
		if (ptr != 0) {

			*(ptr + 1) = '\0';
			pos += ptr - buff + 1;

			lseek (fd, pos, SEEK_SET);
			break;
		}

		offset = buffsize;
		buffsize += 80;
		buff = (char *) realloc (buff, buffsize + 1);
		if (buff == 0)
			break;
	}
	
	if (buff == 0)
		return 0;

	len = strlen (buff);
	if (len >= 1 && buff[len - 1] == '\n')
		buff[len - 1] = '\0';

	len = strlen (buff);
	if (len >= 1 && buff[len - 1] == '\r')
		buff[len - 1] = '\0';

	return (buff);
}

static int
enum_db (int fd, const char *section, char **pkey, char **pval, int idx) {
	char *line;
	int is_in_section;
	int len;
	int i;

	lseek (fd, 0, SEEK_SET);

	i = 0;
	is_in_section = 0;
	for (;;) {
		line = readline (fd);

		if (line == 0)
			break;

		if (line[0] == '\0') {
			Safefree (line);
			continue;
		}

		if (
		is_in_section == 0 &&
		line[0] == '[' &&
		(len = strlen (section)) != 0 &&
		memcmp (&line[1], section, len) == 0 &&
		line[len + 1] == ']') {
			is_in_section = 1;			
			Safefree (line);
			continue;
		}

		if (
		is_in_section != 0 &&
		line[0] == '[') {
			Safefree (line);
			return 0;
		}

		if (is_in_section != 0) {
			char *ptr;
			char *key;
			char *val;
			int keysize;
			int valsize;

			ptr = strchr (line, '=');
			if (ptr == 0) {
				Safefree (line);
				continue;
			}

			if (line[0] == '.' || line[0] == '_') {
				Safefree (line);
				continue;
			}

			if (i < idx) {
				i++;
				Safefree (line);
				continue;
			}

			valsize = strlen (ptr + 1);
      New(101, val, valsize + 1, char);
			if (val == 0) {
				Safefree (line);
				return 0;
			}

			keysize = ptr - line;
      New(101, key, keysize + 1, char);
			if (key == 0) {
				Safefree (val);
				Safefree (line);
				return 0;
			}

			strcpy (val, ptr + 1);
			memcpy (key, line, keysize);
			key[keysize] = '\0';

			Safefree (line);

			if (pkey != 0)
				*pkey = key;

			if (pval != 0)
				*pval = val;

			return 1;
		}

		Safefree (line);
	}

	return 0;
}

static char *
get_value (int fd, const char *section, const char *key) {
	char *line;
	int is_in_section;
	int len;

	lseek (fd, 0, SEEK_SET);

	is_in_section = 0;
	for (;;) {
		line = readline (fd);

		if (line == 0)
			break;

		if (line[0] == '\0') {
			Safefree (line);
			continue;
		}

		if (
		is_in_section == 0 &&
		line[0] == '[' &&
		(len = strlen (section)) != 0 &&
		memcmp (&line[1], section, len) == 0 &&
		line[len + 1] == ']') {
			is_in_section = 1;			
			Safefree (line);
			continue;
		}

		if (
		is_in_section != 0 &&
		(len = strlen (key)) != 0 &&
		memcmp (line, key, len) == 0 &&
		line[len] == '=') {
			char *value;
			int valuesize;

			valuesize = strlen (&line[len + 1]);
			if (valuesize == 0) {
				Safefree (line);
				return 0;
			}

      New(101, value, valuesize + 1, char);

			if (value == 0) {
				Safefree (line);
				return 0;
			}

			strcpy (value, &line[len + 1]);
			Safefree (line);
			return (value);
		}

		Safefree (line);
	}

	return 0;
}

static char *
get_paramfile (char *datadir, char *dbname) {
	char subdirname[] = "config";
	char *filename;
	Stat_t statbuff[1];
	int rc;

	filename = 0;

	/* first look in <sapdbdata>/config if <sapdbdata> is known */
	if (datadir != 0 && datadir[0] != '\0') {
    New(101, filename, strlen (datadir) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1, char);

		if (filename == 0)
			return 0;

		strcpy (filename, datadir);
		strcat (filename, "/");
		strcat (filename, subdirname);
		strcat (filename, "/");
		strcat (filename, dbname);

		rc = stat (filename, statbuff);
	}

	if (rc == 0)
		return (filename);

	if (filename != 0) {
		Safefree (filename);
		filename = 0;
	}

	/* look in /usr/spool/sql/config, maybe DBROOT installation */
	if (rc != 0 && errno == ENOENT) {
    New(101,filename, strlen (sapdb_keyname) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1, char);

		if (filename == 0)
			return 0;

		strcpy (filename, sapdb_keyname);
		strcat (filename, "/");
		strcat (filename, subdirname);
		strcat (filename, "/");	
		strcat (filename, dbname);

		rc = stat (filename, statbuff);
	}

	if (rc == 0)
		return (filename);
	
	if (filename != 0)
		Safefree (filename);

	return 0;
}

static char *
get_dbowner (char *datadir, char *dbname) {
	char subdirname[] = "config";
	char extention[] = "upc";
	char *upcfilename;
	char *dbowner;
	Stat_t statbuff[1];
	struct passwd *pwd;
	int rc;

	/* no file found yet */
	rc = -1;

	/* first look in <sapdbdata>/config if <sapdbdata> is known */
	if (datadir != 0 && datadir[0] != '\0') {
    New(101, upcfilename, strlen (datadir) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1 +
		strlen (extention) + 1, char);
      
		if (upcfilename == 0)
			return 0;

		strcpy (upcfilename, datadir);
		strcat (upcfilename, "/");
		strcat (upcfilename, subdirname);
		strcat (upcfilename, "/");
		strcat (upcfilename, dbname);
		strcat (upcfilename, ".");
		strcat (upcfilename, extention);

		rc = stat (upcfilename, statbuff);
		Safefree (upcfilename);
	}

	/* look in /usr/spool/sql/config, maybe DBROOT installation */
	if (rc != 0 && errno == ENOENT) {
    New(101, upcfilename, strlen (sapdb_keyname) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1 +
		strlen (extention) + 1,char);

		if (upcfilename == 0)
			return 0;

		strcpy (upcfilename, sapdb_keyname);
		strcat (upcfilename, "/");
		strcat (upcfilename, subdirname);
		strcat (upcfilename, "/");	
		strcat (upcfilename, dbname);
		strcat (upcfilename, ".");
		strcat (upcfilename, extention);

		rc = stat (upcfilename, statbuff);
		Safefree (upcfilename);
	}

	if (rc != 0)
		return 0;

	pwd = getpwuid (statbuff->st_uid);

	if (pwd == 0)
		return 0;

  New (101, dbowner, strlen (pwd->pw_name) + 1, char);
	if (dbowner == 0)
		return 0;

	strcpy (dbowner, pwd->pw_name);
	return (dbowner);
}

static info_t *
get_instinfo (char *dbname) {
	int fd;
	struct stat sb[1];
	char *filename;
	char *datadir;
	info_t *info;
	info_t *curr;
	char *val;

	/*
	 * first try to find 75 style globals
	 */
  New (101, filename, strlen (sapdb_globals_filename) + 1,char);
	if (filename == 0)
		return 0;

	strcpy (filename, sapdb_globals_filename);
	
	if (stat (filename, sb) != 0) {
		/*
		 * then try 72, 73 and 74 style globals
		 */
		Safefree (filename);
    New (101, filename, strlen (sapdb_keyname) + 1 + strlen (sapdb_ininame) + 1,char); 
		if (filename == 0)
			return 0;

		strcpy (filename, sapdb_keyname);
		strcat (filename, "/");
		strcat (filename, sapdb_ininame);
	}

	info = 0;
	fd = open (filename , O_RDONLY);
	Safefree (filename);
	if (fd < 0)
		return 0;

	datadir = get_value (fd, "Globals", "IndepData");
	info = infoadd (info, "datadir", datadir);

	info =
	infoadd (info, "progdir", get_value (fd, "Globals", "IndepPrograms"));

	val = get_value (fd, "Globals", "SdbOwner");
	if (val != 0)
		infoadd (info, "user", val);

	val = get_value (fd, "Globals", "SdbGroup");
	if (val != 0)
		infoadd (info, "group", val);

	close (fd);

	/*
	 * look for databases
	 */
	if (dbname != 0) {
		char *mydbname;
		char *myparamfile;
		char *mydbswdir;

		/*
		 * 75 style Databases.ini file
		 */
    New (101, filename, strlen (datadir) + 1 + strlen (sapdb_databases_filename) + 1,char); 

		if (filename == 0) {
			infofree (info);
			return 0;
		}

		strcpy (filename, datadir);
		strcat (filename, "/");
		strcat (filename, sapdb_databases_filename);

		mydbswdir = 0;
		fd = open (filename , O_RDONLY);
		Safefree (filename);
		if (fd >= 0) {
			mydbswdir = get_value (fd, "Databases", dbname);
			close (fd);
		}

		if (mydbswdir == 0) {
			/*
			 * then try 72, 73, 74 style Databases section in SAP_DBTech.ini 
			 */
      New (101, filename, strlen (sapdb_keyname) + 1 + strlen (sapdb_ininame) + 1, char); 

			if (filename == 0) {
				infofree (info);
				return 0;
			}

			strcpy (filename, sapdb_keyname);
			strcat (filename, "/");
			strcat (filename, sapdb_ininame);

			fd = open (filename , O_RDONLY);
			Safefree (filename);
			if (fd >= 0) {
				mydbswdir = get_value (fd, "Databases", dbname);
				close (fd);
			}
		}

    New (101, mydbname, strlen (dbname) + 1, char); 
		if (mydbname == 0) {
			infofree (info);
			return 0;
		}

		strcpy (mydbname, dbname);		
		myparamfile = get_paramfile (datadir, mydbname);

		curr = 0;
		if (mydbname != 0 && myparamfile != 0 && mydbswdir != 0) {
			curr = infoadd (curr, "dbname", mydbname);
			curr = infoadd (curr, "dbswdir", mydbswdir);
			curr = infoadd (curr, "paramfile", myparamfile);
			curr = infoadd (curr, "dbowner",
				get_dbowner (datadir, dbname));
		}

		if (curr != 0)
			info = infoadd (info, "db", (char *) curr);

	} else {
		int i;
		char *dbswdir;
		char *mydbname;
		char *myparamfile;

		/*
		 * first try 75 style Databases.ini file 
		 */
    New (101, filename, strlen (datadir) + 1 + strlen (sapdb_databases_filename) + 1, char); 

		if (filename == 0) {
			infofree (info);
			return 0;
		}

		strcpy (filename, datadir);
		strcat (filename, "/");
		strcat (filename, sapdb_databases_filename);

		fd = open (filename , O_RDONLY);
		Safefree (filename);
		if (fd >= 0) {
			for (i = 0;; i++) {
				if (enum_db (fd, "Databases", &mydbname, &dbswdir, i) == 0)
					break;

				myparamfile = get_paramfile (datadir, mydbname);

				curr = 0;
				if (mydbname != 0 && myparamfile != 0) {
					curr = infoadd (curr, "dbname", mydbname);
					curr = infoadd (curr, "dbswdir", dbswdir);
					curr = infoadd (curr, "paramfile", myparamfile);
					curr = infoadd (curr, "dbowner",
						get_dbowner (datadir, mydbname));
				}

				if (curr != 0)
					info = infoadd (info, "db", (char *) curr);
			}

			close (fd);
		}

		/*
		 * then try 72, 73, 74 style Databases section in SAP_DBTech.ini 
		 */
    New (101, filename, strlen (sapdb_keyname) + 1 + strlen (sapdb_ininame) + 1, char); 

		if (filename == 0) {
			infofree (info);
			return 0;
		}

		strcpy (filename, sapdb_keyname);
		strcat (filename, "/");
		strcat (filename, sapdb_ininame);

		fd = open (filename , O_RDONLY);
		Safefree (filename);
		if (fd >= 0) {
			for (i = 0;; i++) {
				if (enum_db (fd, "Databases", &mydbname, &dbswdir, i) == 0)
					break;

				myparamfile = get_paramfile (datadir, mydbname);

				curr = 0;
				if (mydbname != 0 && myparamfile != 0) {
					curr = infoadd (curr, "dbname", mydbname);
					curr = infoadd (curr, "dbswdir", dbswdir);
					curr = infoadd (curr, "paramfile", myparamfile);
					curr = infoadd (curr, "dbowner",
						get_dbowner (datadir, mydbname));
				}

				if (curr != 0)
					info = infoadd (info, "db", (char *) curr);
			}

			close (fd);
		}
	}

	return (info);
}
#endif

#ifdef WIN32
static const char sapdb_key[] = "SOFTWARE\\SAP\\SAP DBTech";
static const char services_key[] ="SYSTEM\\CurrentControlSet\\Services";
static const char key_prefix[] = "SAP DBTech-";

static int
enum_db (const HKEY their, const char *section, char **pkey, int idx) {
	FILETIME ft[1];
	HKEY our;
	DWORD len;
	char *key;
	int prefix_len;
	int i;
	int j;
	char buff[1024];

	prefix_len = strlen (key_prefix);
	if (RegOpenKeyEx (their, section, 0, KEY_ENUMERATE_SUB_KEYS, &our) != ERROR_SUCCESS)
		return 0;

	i = 0;
	for (j = 0;; j++) {
		if (i > idx)
			break;

		len = sizeof (buff);
		if (RegEnumKeyEx (our, j, buff, &len, 0, 0, 0, ft) != ERROR_SUCCESS) { 
			RegCloseKey (our);
			return 0;
		}

		if (memcmp (buff, key_prefix, prefix_len) != 0)
			continue;

		if (buff[prefix_len] == '.')
			continue;

		if (buff[prefix_len] == '_')
			continue;

		i++;
	}

	RegCloseKey (our);
  New (101, key, strlen (buff) + 1 - prefix_len, char); 

	if (key == 0)
		return 0;

	strcpy (key, &buff[prefix_len]);
	*pkey = key;
	return 1;
}

static char *
get_value (const HKEY their, const char *section, const char *key) {
	HKEY our;
	DWORD type;
	DWORD len;
	char *value;
	char buffer[32 * 1024];

	if (RegOpenKeyEx (their, section, 0, KEY_QUERY_VALUE, &our) != ERROR_SUCCESS)
		return 0;

	if (RegQueryValueEx (our, key, 0 , &type, 0, &len) != ERROR_SUCCESS) {
		RegCloseKey (our);
		return 0;
	}

  New (101, value, len+1, char); 

	if (value == 0) {
		RegCloseKey (our);
		return 0;
	}
	
	if (RegQueryValueEx (our, key, 0 , &type, value, &len) != ERROR_SUCCESS) {
		RegCloseKey (our);
		return 0;
	}

	RegCloseKey (our);

	switch (type) {
	case REG_SZ:
		return (value);

	case REG_EXPAND_SZ:
		ExpandEnvironmentStrings (value, buffer, sizeof (buffer));
		Safefree (value);
	  New (101, value, strlen (buffer) + 1, char); 

		if (value == 0)
			return 0;

		strcpy (value, buffer);
		return (value);
	}
	
	return 0;
}

static char *
get_dbowner (char *dbname) {
	char *owner;
	char *key_name;

	if (dbname == 0 || dbname[0] == '\0')
		return 0;

  New (101, key_name, strlen (services_key) + 1 +
	strlen (key_prefix) + strlen (dbname) + 1, char); 

	if (key_name == 0)
		return 0;

	strcpy (key_name, services_key);
	strcat (key_name, "\\");
	strcat (key_name, key_prefix);
	strcat (key_name, dbname);
	
	owner = get_value (HKEY_LOCAL_MACHINE, key_name, "ObjectName");
	Safefree (key_name);
	
	if (owner == 0)
		return 0;

	if (owner[0] == '\0') {
		Safefree (owner);
		return 0;
	}

	return (owner);
}

static char *
get_paramfile (char *datadir, char *dbswdir, char *dbname) {
	char subdirname[] = "config";
	char *filename;
	Stat_t statbuff[1];
	int rc;

	filename = 0;

	/* first look in <sapdbdata>\config if <sapdbdata> is known */
	if (datadir != 0 && datadir[0] != '\0') {
    New (101, filename, strlen (datadir) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1, char); 

		if (filename == 0)
			return 0;

		strcpy (filename, datadir);
		strcat (filename, "\\");
		strcat (filename, subdirname);
		strcat (filename, "\\");
		strcat (filename, dbname);

		rc = stat (filename, statbuff);
	}

	if (rc == 0)
		return (filename);

	if (filename != 0) {
		Safefree (filename);
		filename = 0;
	}

	/* look in dbswdir\config, maybe DBROOT installation */
	if (rc != 0 && errno == ENOENT && dbswdir != 0 && dbswdir[0] != '\0') {
    New (101, filename, strlen (dbswdir) + 1 +
		strlen (subdirname) + 1 + strlen (dbname) + 1, char); 

		if (filename == 0)
			return 0;

		strcpy (filename, dbswdir);
		strcat (filename, "\\");
		strcat (filename, subdirname);
		strcat (filename, "\\");
		strcat (filename, dbname);

		rc = stat (filename, statbuff);
	}

	if (rc == 0)
		return (filename);
	
	if (filename != 0)
		Safefree (filename);

	return 0;
}

static char *
get_dbswdir (char *dbname) {
	int i;
	char *ptr;
	char *image_name;
	char *key_name;

	if (dbname == 0 || dbname[0] == '\0')
		return 0;

  New (101, key_name, 
	strlen (services_key) + 1 +
	strlen (key_prefix) + strlen (dbname) + 1, char); 

	if (key_name == 0)
		return 0;

	strcpy (key_name, services_key);
	strcat (key_name, "\\");
	strcat (key_name, key_prefix);
	strcat (key_name, dbname);
	image_name = get_value (HKEY_LOCAL_MACHINE, key_name, "ImagePath");
	if (image_name == 0)
		return 0;

	for (i = 0; i <= 1; i++) {
		ptr = strrchr (image_name, '\\');
		if (ptr == 0) {
			Safefree (image_name);
			return 0;
		}

		*ptr = '\0';
	}

	if (image_name[0] == '\0') {
		Safefree (image_name);
		return 0;
	}

  New (101, ptr, strlen (image_name) + 1, char); 
	if (ptr == 0) {
		Safefree (image_name);
		return 0;
	}

	strcpy (ptr, image_name);
	Safefree (image_name);

	return (ptr);
}

static info_t *
get_instinfo (char *dbname) {
	info_t *info;
	info_t *curr;
	char *datadir;

	datadir = get_value (HKEY_LOCAL_MACHINE, sapdb_key, "IndepData");

	info = 0;
	info = infoadd (info, "datadir", datadir);

	info = infoadd (info, "progdir",
	get_value (HKEY_LOCAL_MACHINE, sapdb_key, "IndepPrograms"));

	if (dbname != 0 && dbname[0] != '\0') {
		char *mydbname;
		char *mydbswdir;
		char *myparamfile;

	  New (101, mydbname, strlen (dbname) + 1, char); 

		if (mydbname != 0)
			strcpy (mydbname, dbname);		

		mydbswdir = get_dbswdir (dbname);
		myparamfile = get_paramfile (datadir, mydbswdir, mydbname);; 

		curr = 0;
		if (mydbname != 0 && myparamfile != 0) {
			curr = infoadd (curr, "dbname", mydbname);
			curr = infoadd (curr, "dbswdir", mydbswdir);
			curr = infoadd (curr, "dbowner", get_dbowner (mydbname));
			curr = infoadd (curr, "paramfile", myparamfile);
		}

		if (curr != 0)
			info = infoadd (info, "db", (char *) curr);
	} else {
		int i;

		for (i = 0;; i++) {
			char *mydbname=NULL;
			char *mydbswdir=NULL;
			char *myparamfile=NULL;

			if (enum_db (HKEY_LOCAL_MACHINE, services_key, &mydbname, i) == 0)
				break;

			if (mydbname != 0) {
				mydbswdir = get_dbswdir (mydbname);
				myparamfile = get_paramfile (datadir, mydbswdir, mydbname);
			}

			curr = 0;
			if (mydbname != 0 && myparamfile != 0) {
				curr = infoadd (curr, "dbname", mydbname);
				curr = infoadd (curr, "dbswdir", mydbswdir);
				curr = infoadd (curr, "dbowner", get_dbowner (mydbname));
				curr = infoadd (curr, "paramfile", myparamfile);
			}

			if (curr != 0)
				info = infoadd (info, "db", (char *) curr);
		}
	}

	return (info);
}
#endif

/*
 * will return a structure like this or undef
 *
 * ref-+->progdir
 *     |
 *     +->datadir
 *     |
 *     +->user
 *     |
 *     +->group
 *     |
 *     +->database-+->SID0-+->dbname
 *                 |       |
 *                 |       +->dbowner
 *                 |       |
 *                 |       +->dbswdir
 *                 |
 *                 +->SID1-+->dbname
 *                 |       |
 *                 |       +->dbowner
 *                 |       |
 *                 |       +->dbswdir
 *                ...
 *
 * expects one parameter,
 * this is the name of the database we are looking for
 *
 * if no parameter is given,
 * it will look for all know database instances
 */

DBISTATE_DECLARE;

/*
* The source code of the package BD::MaxDB::util is taken from
* MaxDB's installation tool sdbinst. 
*
* :install56\perl\sdbrun\InstInfo.xs
*
* Thanks to ChristophB
*/


MODULE = DBD::MaxDB    PACKAGE = DBD::MaxDB::InstInfo

PROTOTYPES: DISABLE

void
new (...)
PREINIT:
	char *dbname;
	info_t *info;
	info_t *curr0;
	info_t *curr1;
	HV *hv0;
	HV *hv1;
	HV *hv2;
	SV *rv;
PPCODE:
	if (items >= 2)
		XSRETURN_UNDEF;

	dbname = 0;
	if (items == 1 && SvPOKp (ST(0)))
		dbname = (char *) SvPV (ST(0), PL_na);		

	info = get_instinfo (dbname);
	if (info == 0)
		XSRETURN_UNDEF;

	hv0 = newHV ();
	hv1 = 0;

	for (curr0 = info; curr0 != 0; curr0 = curr0->next) {
		if (curr0->key == 0)
			continue;

		if (strcmp (curr0->key, "db") == 0) {
			if (curr0->val == 0)
				continue;

			if (hv1 == 0)
				hv1 = newHV ();

			hv2 = newHV ();
			for (curr1 = (info_t *)(curr0->val); curr1 != 0; curr1 = curr1->next) {
				if (curr1->key == 0)
					continue;

				if (strcmp (curr1->key, "dbname") == 0) {
				  New (101, dbname, strlen (curr1->val) + 1, char); 

					if (dbname == 0)
						break;

					strcpy (dbname, curr1->val);
				}

				if (curr1->val == 0) {
					hv_store (
					hv2, curr1->key, strlen (curr1->key),
					newSVpv ("", 0), 0);
					continue;
				}

				if (strcmp (curr1->key, "dbswdir") == 0 ||
				    strcmp (curr1->key, "paramfile") == 0) {
					char *ptr;

					for (ptr = curr1->val; *ptr != 0; ptr++)
						if (*ptr == '\\')
							*ptr = '/';
				}

				hv_store (
				hv2, curr1->key, strlen (curr1->key),
				newSVpv (curr1->val, strlen (curr1->val)), 0);
			}

			rv = newRV ((SV *) hv2);
			SvREFCNT_dec (hv2);
			hv_store (hv1, dbname, strlen (dbname), rv, 0);
			Safefree (dbname);
			continue;
		}

		if (curr0->val == 0) {
			hv_store (
			hv0, curr0->key, strlen (curr0->key),
			newSVpv ("", 0), 0);
			continue;
		}

		if (strcmp (curr0->key, "progdir") == 0 ||
		    strcmp (curr0->key, "datadir") == 0 ||
		    strcmp (curr0->key, "uid") == 0 ||
		    strcmp (curr0->key, "gid") == 0 ||
		    strcmp (curr0->key, "user") == 0 ||
		    strcmp (curr0->key, "group") == 0) {
			char *ptr;

			for (ptr = curr0->val; *ptr != 0; ptr++)
				if (*ptr == '\\')
					*ptr = '/';
		}

		hv_store (
		hv0, curr0->key, strlen (curr0->key),
		newSVpv (curr0->val, strlen (curr0->val)), 0);
	}

	if (hv1 != 0) {
		rv = newRV ((SV *) hv1);
		SvREFCNT_dec (hv1);
		hv_store (hv0, "database", 8, rv, 0);
	}

	infofree (info);

	rv = sv_2mortal (newRV ((SV *) hv0));
	SvREFCNT_dec (hv0);

	XPUSHs (rv);
	XSRETURN (1);
	
MODULE = DBD::MaxDB    PACKAGE = DBD::MaxDB

INCLUDE: MaxDB.xsi

MODULE = DBD::MaxDB    PACKAGE = DBD::MaxDB::dr

MODULE = DBD::MaxDB    PACKAGE = DBD::MaxDB::db

void
_ping(dbh)
  SV *  dbh
  CODE:
  ST(0) = dbd_maxdb_db_ping(dbh)? &sv_yes : &sv_no;

void
_isunicode(dbh)
  SV *  dbh
  CODE:
  ST(0) = dbd_maxdb_db_isunicode(dbh)? &sv_yes : &sv_no;

void
_getSQLMode(dbh)
    SV *  dbh
    CODE:
  ST(0) = dbd_maxdb_db_getSQLMode(dbh);

void
_getVersion(dbh)
    SV *  dbh
    CODE:
  ST(0) = dbd_maxdb_db_getVersion(dbh);

void
_executeUpdate( dbh, stmt )
SV *        dbh
SV *        stmt
CODE:
{
   ST(0) = sv_2mortal(newSViv((IV)dbd_maxdb_db_executeUpdate(dbh, stmt)));
}
  
MODULE = DBD::MaxDB    PACKAGE = DBD::MaxDB::st

void
_Cancel(sth)
    SV *  sth

    CODE:
  ST(0) = dbd_maxdb_st_cancel(sth);

void
_executeInternal( dbh, sth, stmt )
SV *        dbh
SV*         sth
SV *        stmt
CODE:
{
   STRLEN lna;
   char *pstmt = SvOK(stmt) ? SvPV(stmt,lna) : "";
   ST(0) = sv_2mortal(newSViv((IV)dbd_maxdb_db_executeInternal(dbh, sth, pstmt)));
}

