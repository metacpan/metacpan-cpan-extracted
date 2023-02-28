   	SUBROUTINE rdata(Amp, ntrmax, nsmax, ntr, ns,
     + Amp_min, Amp_max)     
! ****************************************************
	INTEGER*4 ntrmax,n,ntr,ns
	REAL*4 Amp(ntrmax,nsmax), Amp_min, Amp_max
       character*300 inbound_bin
       character*300 inbound_config
       character*40 base_file
       character*40 config_file
       character*255 set_DIR,get_DIR
       real*4        result(30)

      config_file  = "immodpg.config"
      config_file  = trim(config_file)

! define the different needed directories
      set_DIR = "IMMODPG"
      call Project_config(set_DIR,get_DIR)
!      print*,'immodpg.for,rdata,get_DIR:',get_DIR
      
!  define needed files
      inbound_config = trim(get_DIR)//"/"//config_file 
! config_file
!      print*,'immodpg.for,rdata,inbound_config:',inbound_config
!   read all the configuration parameters for immodpg
      call read_immodpg_config(base_file,result,inbound_config)

!      print*,'immodpg.for,rdata,base_file:',trim(base_file)
      
! define the different, needed directories
      set_DIR        = "DATA_SEISMIC_BIN"
      call Project_config(set_DIR,get_DIR)
      inbound_bin = trim(get_DIR)//"/"//trim(base_file)//'.bin'
!      print*,'1179immodpg.for,rdata,base_file:',inbound_bin
!      print*,'next line'
!      print*,'1218-immodpg.for,rdata,inbound_bin:',trim(inbound_bin)

! Read data File
      call read_bin_data (inbound_bin,ntrmax,nsmax,ntr,ns,Amp)

      Amp_min = 1e30
      Amp_max = -1e30
      do 20 i=1,ntr
      
         do 11 j=1,ns
            Amp_min = min(Amp(i,j),Amp_min)
            Amp_max = max(Amp(i,j),Amp_max)
 11      continue

 20   continue
!	print*, 'immodpg.for,rdata, Data min,max=',Amp_min,Amp_max
!	print*, 'immodpg.for, L 1197, rdata, finished reading data'

      return
      END ! of subroutine

