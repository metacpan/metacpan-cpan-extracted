/* 
 * the playlist struct 
 */

struct playlist {
    /* functions */
    char * (*next)(struct playlist *);
    /* data */
    char **shufflist;
    int *shuffleord;
    int shuffle_listsize;
    char *listname;
    char *listnamedir;
    FILE *listfile;
    int curfile;
    int loptind;
};


struct playlist *new_playlist(int argc,char **argv,char *listname, int loptind);



