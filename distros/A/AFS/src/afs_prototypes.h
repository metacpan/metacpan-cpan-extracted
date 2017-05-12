/*
 * afs_prototypes.h for AFS Perl Extension module
 *
 * Prototypes for OpenAFS subroutines
 * picked up from the OpenAFS header files
 */

#if defined(OpenAFS_1_0) || defined(OpenAFS_1_1) || defined(OpenAFS_1_2) || defined(OpenAFS_1_3)
extern const char *error_message();
#endif
extern int UV_SetSecurity(struct rx_securityClass *, afs_int32);
extern char *hostutil_GetNameByINet();
extern struct hostent *hostutil_GetHostByName(register char *ahost);
extern char *volutil_PartitionName();
extern int afsconf_ClientAuthSecure(struct afsconf_dir *,struct rx_securityClass **, int *);
extern int afsUUID_from_string(const char *str, afsUUID * uuid);
extern int afsUUID_to_string(const afsUUID * uuid, char *str, size_t strsz);
extern int des_read_pw_string(char *, int, char *, int);
extern int Lp_GetRwIndex(struct nvldbentry *);
extern int Lp_ROMatch(afs_int32, afs_int32, struct nvldbentry *entry);
extern void MapPartIdIntoName(afs_int32 partId, char *partName);
extern void MapNetworkToHost(struct nvldbentry *old, struct nvldbentry *new);
extern void MapHostToNetwork(struct nvldbentry *entry);
extern int pioctl(char *,int, struct ViceIoctl *, int);
extern int PrintError(char *msg, afs_int32 errcode);
extern char *re_comp(char *sp);
extern int rc_exec(char *p);
extern int setpag();
extern int ubik_Call();
extern int ubik_Call_New();
#ifdef OpenAFS_1_4_07
extern int UV_AddSite(afs_int32 server, afs_int32 part, afs_int32 volid, afs_int32 valid);
#else
extern int UV_AddSite(afs_int32 server, afs_int32 part, afs_int32 volid);
#endif
extern int UV_AddSite2(afs_int32 server, afs_int32 part, afs_uint32 volid,
                       afs_uint32 rovolid, afs_int32 valid);
extern int UV_BackupVolume(afs_int32 aserver, afs_int32 apart, afs_int32 avolid);
extern int UV_ChangeLocation(afs_int32 server, afs_int32 part, afs_int32 volid);
extern int UV_CreateVolume2(afs_int32 aserver, afs_int32 apart, char *aname,
                            afs_int32 aquota, afs_int32 aspare1,
                            afs_int32 aspare2, afs_int32 aspare3,
                            afs_int32 aspare4, afs_int32 * anewid);
extern int UV_CreateVolume3(afs_int32 aserver, afs_int32 apart, char *aname,
                            afs_int32 aquota, afs_int32 aspare1,
                            afs_int32 aspare2, afs_int32 aspare3,
                            afs_int32 aspare4, afs_uint32 * anewid,
                            afs_uint32 * aroid, afs_uint32 * abkid);
extern int UV_DeleteVolume(afs_int32 aserver, afs_int32 apart,
                           afs_int32 avolid);
#if defined(OpenAFS_1_4_05)
extern int UV_DumpVolume(afs_int32 afromvol, afs_int32 afromserver,
                         afs_int32 afrompart, afs_int32 fromdate,
                         afs_int32(*DumpFunction) (), char *rock, afs_int32 flags);
#else
extern int UV_DumpVolume(afs_int32 afromvol, afs_int32 afromserver,
                         afs_int32 afrompart, afs_int32 fromdate,
                         afs_int32(*DumpFunction) (), char *rock);
#endif
extern int UV_DumpClonedVolume(afs_int32 afromvol, afs_int32 afromserver,
                               afs_int32 afrompart, afs_int32 fromdate,
                               afs_int32(*DumpFunction) (), char *rock,
                               afs_int32 flags);
extern int UV_ListOneVolume(afs_int32 aserver, afs_int32 apart,
                            afs_int32 volid, struct volintInfo **resultPtr);
extern int UV_ListPartitions(afs_int32 aserver, struct partList *ptrPartList,
                             afs_int32 * cntp);
extern int UV_ListVolumes(afs_int32 aserver, afs_int32 apart, int all,
                          struct volintInfo **resultPtr, afs_int32 * size);

extern int UV_LockRelease(afs_int32 volid);

extern int UV_MoveVolume(afs_int32 afromvol, afs_int32 afromserver,
                         afs_int32 afrompart, afs_int32 atoserver,
                         afs_int32 atopart);
#ifdef OpenAFS_1_4_64
extern int UV_PartitionInfo64(afs_int32 server, char *pname,
                            struct diskPartition64 *partition);
#else
extern int UV_PartitionInfo(afs_int32 server, char *pname,
                            struct diskPartition *partition);
#endif
extern int UV_ReleaseVolume(afs_int32 afromvol, afs_int32 afromserver,
                            afs_int32 afrompart, int forceflag);

extern int UV_RemoveSite(afs_int32 server, afs_int32 part, afs_int32 volid);
extern int UV_RenameVolume(struct nvldbentry *entry, char oldname[],
                           char newname[]);
extern int UV_RestoreVolume(afs_int32 toserver, afs_int32 topart,
                            afs_int32 tovolid, char tovolname[], int restoreflags,
                            afs_int32(*WriteData) (), char *rock);
extern int UV_SetVolume(afs_int32 server, afs_int32 partition,
                        afs_int32 volid, afs_int32 transflag,
                        afs_int32 setflag, int sleeptime);
extern int UV_SetSecurity();
#ifdef OpenAFS
extern int UV_SetVolumeInfo(afs_int32 server, afs_int32 partition,
                            afs_int32 volid, volintInfo * infop);
#endif
extern int UV_SyncServer(afs_int32 aserver, afs_int32 apart, int flags,
                         int force);
extern int UV_SyncVolume(afs_int32 aserver, afs_int32 apart, char *avolname,
                         int flags);
extern int UV_SyncVldb(afs_int32 aserver, afs_int32 apart, int flags,
                       int force);
extern int UV_VolserStatus(afs_int32 server, transDebugInfo ** rpntr,
                           afs_int32 * rcount);

extern int UV_VolumeZap(afs_int32 server, afs_int32 part, afs_int32 volid);
extern int UV_NukeVolume(afs_int32 server, afs_int32 partid, afs_int32 volid);
extern int UV_XListVolumes(afs_int32 a_serverID, afs_int32 a_partID,
                           int a_all, struct volintXInfo **a_resultPP,
                           afs_int32 * a_numEntsInResultP);

extern int VLDB_GetEntryByID(afs_int32, afs_int32, struct nvldbentry *);
extern int VLDB_GetEntryByName(char *, struct nvldbentry *);
extern int VLDB_IsSameAddrs(afs_int32, afs_int32, afs_int32 *);
extern int VLDB_ListAttributes(VldbListByAttributes *attrp, afs_int32 *entriesp, nbulkentries *blkentriesp);
extern int VLDB_ListAttributesN2(VldbListByAttributes *attrp, char *name, afs_int32 thisindex,
           afs_int32 *nentriesp, nbulkentries *blkentriesp, afs_int32 *nextindexp);
extern int VL_ChangeAddr( struct rx_connection *z_conn, afs_int32, afs_int32);
extern int VL_DeleteEntry(struct rx_connection *,afs_int32, afs_int32 );
extern int VL_GetAddrs( struct rx_connection *, afs_int32 Handle, afs_int32, VLCallBack *,
           afs_int32 * nentries, bulkaddrs *);
extern int VL_GetAddrsU(struct rx_connection *z_conn, ListAddrByAttributes * inaddr,
           afsUUID * uuidp1, afs_int32 * uniquifier, afs_int32 * nentries, bulkaddrs * blkaddrs);
extern int VL_SetLock(struct rx_connection *z_conn, afs_int32 Volid, afs_int32 voltype,
           afs_int32 voloper);
extern int VL_ReleaseLock(struct rx_connection *z_conn, afs_int32 Volid, afs_int32 voltype,
           afs_int32 ReleaseType);
/* extern void des_string_to_key(char *str, register des_cblock * key); */
extern void des_string_to_key();
#if defined(OpenAFS_1_4) || defined(OpenAFS_1_5)
extern int vsu_ExtractName(char rname[], char name[]);
#endif
extern afs_uint32 util_GetUInt32(register char *as, afs_uint32 * aval);
extern afs_int32 util_GetInt32(register char *as, afs_int32 * aval);
