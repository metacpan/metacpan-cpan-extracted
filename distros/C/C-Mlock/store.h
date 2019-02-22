typedef struct
{
    int   nSize;         /* Number of pages requested */
    int   nBytes;        /* Number of bytes available */
    int   sBytes;        /* Stored bytes */
    int   nPageSize;     /* Page size in bytes */
    char *pBytes;        /* pointer to available memory */
    int   memLocked;     /* mlock() has been called on a specific memory region */
    int   processLocked; /* mlockall() has been called */
} AddressRegion;

extern AddressRegion *new            (int nSize);
extern int            initialize     (AddressRegion *pAddressRegion);
extern void           DESTROY        (AddressRegion *pAddressRegion);
extern void           dump           (AddressRegion *pAddressRegion);
extern int            store          (AddressRegion *pAddressRegion, char *data, int len);
extern char          *get            (AddressRegion *pAddressRegion);
extern int            lockall        (AddressRegion *pAddressRegion);
extern int            unlockall      (AddressRegion *pAddressRegion);

extern int            set_pages      (AddressRegion *pAddressRegion, int pages);
extern int            set_size       (AddressRegion *pAddressRegion, int bytes);
extern int            pagesize       (AddressRegion *pAddressRegion);
extern int            is_locked      (AddressRegion *pAddressRegion);
extern int            process_locked (AddressRegion *pAddressRegion);
