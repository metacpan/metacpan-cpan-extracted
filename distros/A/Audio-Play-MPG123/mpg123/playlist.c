/* 
 * moved all playlist related functions to this new file
 * The "Shuffle" part is now also used for simple non random
 * playlists. 
 *
 */ 

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include "mpg123.h"
#include "playlist.h"

static void shuffle_files(struct playlist *playlist,int numfiles)
{
    int loop, rannum;

    srand(time(NULL));
    if(playlist->shuffleord)
	free(playlist->shuffleord);
    playlist->shuffleord = (int *) malloc((numfiles + 1) * sizeof(int));
    if (!playlist->shuffleord) {
	perror("malloc");
	exit(1);
    }
    /* write songs in 'correct' order */
    for (loop = 0; loop < numfiles; loop++) {
	playlist->shuffleord[loop] = loop;
    }

    /* now shuffle them */
    if(numfiles >= 2) {
	for (loop = 0; loop < numfiles; loop++) {
	    rannum = (rand() % (numfiles * 4 - 4)) / 4;
	    rannum += (rannum >= loop);
	    playlist->shuffleord[loop] ^= playlist->shuffleord[rannum];
	    playlist->shuffleord[rannum] ^= playlist->shuffleord[loop];
	    playlist->shuffleord[loop] ^= playlist->shuffleord[rannum];
	}
    }
}

static int find_next_file (struct playlist *playlist, int argc , char **argv,char *line)
{
    char linetmp [1024];
    char * slashpos;
    int i;

    /* Get playlist dirname to append it to the files in playlist */
    if (playlist->listname) {
	if ((slashpos=strrchr(playlist->listname, '/'))) {
	    playlist->listnamedir=strdup (playlist->listname);
	    playlist->listnamedir[1 + slashpos - playlist->listname] = 0;
	}
    }

    if (playlist->listname && !playlist->listfile) {
	if (!*(playlist->listname) || !strcmp(playlist->listname, "-")) {
	    playlist->listfile = stdin;
	    playlist->listname = NULL;
	}
	else if (!strncasecmp(playlist->listname, "http://", 7))  {
	    int fd;
	    fd = http_open(playlist->listname);
	    if(fd < 0)
		return 0;
	    playlist->listfile = fdopen(fd,"r");
	}
        else if (!strncasecmp(playlist->listname, "ftp://", 6))  {
            int fd;
            fd = http_open(playlist->listname);
            if(fd < 0)
                return 0;
            playlist->listfile = fdopen(fd,"r");
        }
	else if (!(playlist->listfile = fopen(playlist->listname, "rb"))) {
	    perror (playlist->listname);
	    playlist->listfile = NULL;
	}
	if (playlist->listfile && param.verbose)
	    fprintf (stderr, "Using playlist from %s ...\n",
		     playlist->listname ? playlist->listname : "standard input");
    }

    if(playlist->listfile) {
	do {
	    if (fgets(line, 1023, playlist->listfile)) {
		i = strcspn(line, "\t\n\r");
		/*                line[i] = '\0'; */
		/* kill useless spaces at the end of the string*/
		{
		    char *c_line = &line[i-1];
		    while (i--){
			if (*c_line == ' ')
			    c_line--;
			else 
			    *(++c_line) = '\0';
		    }
		} 
	
#if !defined(WIN32)
		/* MS-like directory format */
		for (i=0;line[i]!='\0';i++)
		    if (line [i] == '\\')
			line [i] = '/';
#endif
		if (line[0]=='\0' || line[0]=='#')
		    continue;
		if ((playlist->listnamedir) && (line[0]!='/') && (line[0]!='\\') 
                    && (strncasecmp(line, "http://", 7)) && (strncasecmp(line, 
"ftp://",6)) ){
		    strcpy (linetmp, playlist->listnamedir);
		    strcat (linetmp, line);
		    strcpy (line, linetmp);
		}
		return 1;
	    }
	    else {
		if (playlist->listname)
		    fclose (playlist->listfile);
		playlist->listname = NULL;
		playlist->listfile = NULL;
	    }
	} while (playlist->listfile);
    }

    if (playlist->loptind < argc) {
	strncpy(line,argv[playlist->loptind++], 1023);
	return 1;
    }

    return 0;
}

static char *get_next_file(struct playlist *playlist)
{
    char *newfile;

    if (!playlist->shufflist || !playlist->shufflist[playlist->curfile]) {
	return NULL;
    }

    if(param.shuffle == 1) {
	if (playlist->shuffleord) {
	    newfile = playlist->shufflist[playlist->shuffleord[playlist->curfile]];
	} else {
	    newfile = playlist->shufflist[playlist->curfile];
	}
	playlist->curfile++;
    }
    else if (param.shuffle == 2) {
	newfile = playlist->shufflist[ rand() % playlist->shuffle_listsize ];
    }
    else {
	newfile = playlist->shufflist[playlist->curfile];
	playlist->curfile++;
    }

    return newfile;
}

struct playlist *new_playlist (int argc, char **argv, char *listname, int loptind)
{
    struct playlist *playlist;
    char line[1024];

    int ret;
    int mallocsize = 0;
    char *tempstr;
    
    if (param.remote) 
	return NULL;

    playlist = (struct playlist *) malloc(sizeof(struct playlist));
    if(!playlist)
	return NULL;

    memset(playlist,0,sizeof(struct playlist));
    playlist->listname = listname;

    playlist->next = get_next_file;
    playlist->loptind = loptind;

    while ( (ret=find_next_file(playlist,argc,argv,line)) != 0 ) {
	tempstr = line;
	if (playlist->shuffle_listsize + 2 > mallocsize) {
	    mallocsize += 8;
	    playlist->shufflist = (char **) realloc(playlist->shufflist, 
						    mallocsize * sizeof(char *));
	    if (!playlist->shufflist) {
		perror("realloc");
		exit(1);
	    }
	}
	if (!(playlist->shufflist[playlist->shuffle_listsize] = (char *) 
	      malloc(strlen(tempstr) + 1))) {
	    perror("malloc");
	    exit(1);
	}
	strcpy(playlist->shufflist[playlist->shuffle_listsize], tempstr);
	playlist->shuffle_listsize++;
    }
    if (playlist->shuffle_listsize) {
	if (playlist->shuffle_listsize + 1 < mallocsize) {
	    playlist->shufflist = 
		(char **) realloc(playlist->shufflist, 
				  (playlist->shuffle_listsize + 1) * sizeof(char *));
	}
	playlist->shufflist[playlist->shuffle_listsize] = NULL;
    }

    if(param.shuffle > 0)
	shuffle_files(playlist,playlist->shuffle_listsize);

    return playlist;
}





