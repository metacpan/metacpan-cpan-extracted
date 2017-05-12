#ifndef CACHE_FIX_H_INCLUDED
# define CACHE_FIX_H_INCLUDED 1

# define IO_GAMES 1             /* undo cache's ioctl games */
# define SIGNAL_GAMES 1         /* undo cache's signal games */

# if IO_GAMES
extern int perl_is_master;
void cac_tty_save(void);
void cac_tty_restore(void);
#  define TTY_SAVE do { if(perl_is_master) cac_tty_save(); } while(0)
#  define TTY_RESTORE do { if(perl_is_master) cac_tty_restore(); } while(0)
# else
#  define TTY_SAVE
#  define TTY_RESTORE
# endif
# if SIGNAL_GAMES
extern int perl_is_master;
void cac_tty_save(void);
void cac_tty_restore(void);
#  define SIGNAL_SAVE do { if(perl_is_master) cac_signal_save(); } while(0)
#  define SIGNAL_RESTORE do { if(perl_is_master) cac_signal_restore(); } while(0)
# else
#  define SIGNAL_SAVE
#  define SIGNAL_RESTORE
# endif
#endif
