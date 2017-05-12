App-Squid-Redirector-Fugu
=========================


###Sample of fugu.conf

```javascript

{
	"bdbdir": "/var/lib/fugu",
	"logdir": "/var/log/squid3",

	"dbdsn": "dbi:mysql:mydbname;host=192.168.1.48",
	"dbuser": "mydbuser",
	"dbpassword": "mydbpassword",

    "ldapserver": "server.domain.local",
	"ldapdn": "cn=myldapuser,ou=Department,dc=domain,dc=local",
	"ldappassword": "myldappassword",

	"time": {
		"work": [
			{ "smtwhfa": "10:00-12:00" },
			{ "smtwhfa": "13:30-18:00" }
		],
		"nowork": [
			{ "smtwhfa": "18:01-09:59" },
			{ "smtwhfa": "12:01-13:29" }
		]
	},

	"src": { 
        "finance": {
            "ip_sql": "select address from user where department='finance' and active='Y'"
        },
        "humanresources": {
            "ip_file": "humanresources-ips"
        },        
        "it": {
            "user_sql": "select login from user where department='it' and active='Y'"
        },
        "marketing": {
            "user_file": "marketing-users"
        },
        "production": {
            "user_ldap_base": "dc=domain,dc=local",
	        "user_ldap_filter": "(&(objectclass=person)(memberof=cn=production,ou=Groups,dc=domain,dc=local))",
            "user_ldap_attr": "sAMAccountName"            
        },
        "purchasing": {
            "user_ldap_base": "dc=domain,dc=local",
	        "user_ldap_filter": "(&(objectclass=person)(memberof=cn=purchasing,ou=Groups,dc=domain,dc=local))",
            "user_ldap_attr": "sAMAccountName"            
        }             
	},

	"dst": {
		"exe": {
			"expression_file": "exe-expressions"
		},
		"socialnet": {
			"domain_file": "socialnet-domains"
		},
		"porn": {
		    "domain_file": "porn-domains",
			"url_file": "porn-urls"
		},		
		"allowed": {
			"domain_file": "allowed-domains",
			"url_file": "allowed-urls"
		},
		"denied": {
		    "domain_sql": "select domain from table_domain where category='denied'",
		    "url_sql": "select url from table_url where category='denied'"
		}
	},

	"access": [
		{
		    "src": "it",
			"pass": [
			    "!porn",
			    "all"
			]
		},
		{
		    "src": "humanresources",
			"pass": [
			    "allowed",
			    "socialnet",
			    "none"
			]
		},
		{
		    "src": "production",
			"pass": [
			    "allowed",
			    "none"
			]
		},									
		{
		    "src": "default",
		    "time": "work",
			"pass": [
			    "allowed",
			    "!exe",
			    "!socialnet",
			    "!porn",
				"none"
			],
			"redirect": {
			    "http": "http://www.google.com",
			    "https": "www.google.com:443"
		    }
		},
		{
		    "src": "default",
		    "time": "nowork",
			"pass": [
			    "!exe",
			    "!porn",
				"all"
			],
			"redirect": {
			    "http": "http://www.google.com",
			    "https": "www.google.com:443"
		    }
		}		
	]

}

```


###Building domains and URLs DBs

```
    fugu-build --config /etc/fugu.conf
```


###Configuring squid.conf

```
    url_rewrite_program fugu --config /etc/fugu.conf
```
