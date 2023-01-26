      subroutine Project_config (set_DIR,get_DIR)

!      use variables
      implicit none
!       read a configuration file
      integer :: result
      character (len=80) :: inbound, equal, answer
      character (len=30) :: format0,format1,format2,format3
      character (len=30) :: format4,format5,format6
      character (len=30) :: format7,format8,format9
      character (len=30) :: format10,format11,format12,format13
      character (len=30) :: format14,format15,format16
      character (len=255) :: set_DIR, get_DIR, path,Project_conf_file
      character (len=255) :: temp
      character (len=255) :: HOME, PROJECT_HOME, site, spare_dir
      character (len=255) :: date, component, line, subUser
      character (len=255) :: geomaps, geopsy,gmt, grass
      character (len=255) :: matlab, mmodpg, sqlite
      character (len=255) :: HOME_n, PROJECT_HOME_n,site_n,spare_dir_n
      character (len=255) :: date_n, component_n,line_n,subUser_n
      character (len=255) :: geomaps_n,geopsy_n,gmt_n,grass_n
      character (len=255) :: matlab_n, mmodpg_n, sqlite_n

!      define formats
      format1= "(A4,31X,A1,1X,A)"
      format2= "(A12,23X,A1,1X,A)"
      format3 = format1
      format4 = "(A9,26X,A1,1X,A)"
      format5 = format1
      format6 = format4
      format7 = format1
      format8 = "(A8,27X,A1,1X,A)"
      format9 = format8
      format10 = "(A6,29X,A1,1X,A)"
      format11 = "(A3,32X,A1,1X,A)"
      format12 = "(A5,30X,A1,1X,A)"
      format13 = format10
      format14 = format10
      format15 = format10

!      get user's home directory
      CALL get_environment_variable("HOME",HOME)
      path = "/.L_SU/configuration/active/Project.config"
      inbound = trim(HOME)//path
!      print *, 'Project_config.f,  Project_config_file:',inbound

!      read active Project configuration file
      open(unit=1,file=inbound,status='old')
!      print * , 'Project_config.f,  Project_config_file:',inbound
       read (1,format1) HOME_n,equal,HOME
       read (1,format2) PROJECT_HOME_n,equal,PROJECT_HOME
       read (1,format3) site_n,equal,site
       read (1,format4) spare_dir_n,equal,spare_dir
       read (1,format5) date_n,equal,date
       read (1,format6) component_n,equal,component
       read (1,format7) line_n,equal,line
       read (1,format8) subUser_n,equal,subUser
       read (1,format9) geomaps_n,equal,geomaps
       read (1,format10) geopsy_n,equal,geopsy
       read (1,format11) gmt_n,equal,gmt
       read (1,format12) grass_n,equal,grass
       read (1,format13) matlab_n,equal,matlab
       read (1,format14) mmodpg_n,equal,mmodpg
       read (1,format15) sqlite_n,equal,sqlite

      close(unit=1)

!      print *, 'Project_config.f,HOME_n=',trim(home_n)
!      print *, 'Project_config.f,HOME,HOME=',trim(HOME)
!      print *, 'Project_config.f,PROJECT_HOME_n=',trim(PROJECT_HOME_n)
!      print *, 'Project_config.f,PROJECT_HOME=',trim(PROJECT_HOME)
!      print *, 'Project_config.f,site_n=',trim(site_n)
!      print *, 'Project_config.f,site=',trim(site)
!      print *, 'Project_config.f,spare_dir=',trim(spare_dir)
!      print *, 'Project_config.f,spare_dir_n=',trim(spare_dir_n)
!      print *, 'Project_config.f,date_n=',trim(date_n)
!      print *, 'Project_config.f,date=',trim(date)
!      print *, 'Project_config.f,component_n=',trim(component_n)
!      print *, 'Project_config.f,component=',trim(component)
!      print *, 'Project_config.f,line_n=',trim(line_n)
!      print *, 'Project_config.f,line=',trim(line)
!      print *, 'Project_config.f,subUser_n=',trim(subUser_n)
!      print *, 'Project_config.f,subUser=',trim(subUser)
!      print *, 'Project_config.f,geomaps_n=',trim(geomaps_n)
!      print *, 'Project_config.f,geomaps=',trim(geomaps)
!      print *, 'Project_config.f,gmt_n=',trim(gmt_n)
!      print *, 'Project_config.f,gmt=',trim(gmt)
!      print *, 'Project_config.f,grass_n=',trim(grass_n)
!      print *, 'Project_config.f,grass=',trim(grass)
!      print *, 'Project_config.f,matlab_n=',trim(matlab_n)
!      print *, 'Project_config.f,matlab=',trim(matlab)
!      print *, 'Project_config.f,mmodpg_n=',trim(mmodpg_n)
!      print *, 'Project_config.f,mmodpg=',trim(mmodpg)
!      print *, 'Project_config.f,sqlite_n=',trim(sqlite_n)
!      print *, 'Project_config.f,sqlite=',trim(sqlite)
!       print *, '1 Project_config.f, get_DIR:',trim(set_DIR)

      if (trim(set_DIR) == 'IMMODPG') then

       temp = trim(PROJECT_HOME)//"/seismics/mmodpg/"//trim(site)
       temp = trim(temp)//"/"//trim(spare_dir)//"/"//trim(date)
       temp = trim(temp)//"/"//trim(component)//"/"//trim(line)
       temp = trim(temp)//"/"//trim(subUser)
       get_DIR = temp
!       print *, '2 Project_config.f, get_DIR:',trim(get_DIR)

      end if

      if (trim(set_DIR) == 'IMMODPG_INVISIBLE') then

       temp = trim(PROJECT_HOME)//"/seismics/mmodpg/"//trim(site)
       temp = trim(temp)//"/"//trim(spare_dir)//"/"//trim(date)
       temp = trim(temp)//"/"//trim(component)//"/"//trim(line)
       temp = trim(temp)//"/"//trim(subUser)//"/.immodpg"
       get_DIR = temp
!       print *, '3 Project_config.f, get_DIR:',get_DIR

      end if

      if (trim(set_DIR) == 'DATA_SEISMIC_BIN') then

       temp = trim(PROJECT_HOME)//"/seismics/data/"//trim(site)
       temp = trim(temp)//"/"//trim(spare_dir)//"/"//trim(date)
       temp = trim(temp)//"/"//trim(component)//"/"//trim(line)
       temp = trim(temp)//"/"//"bin"
       temp = trim(temp)//"/"//trim(subUser)
       get_DIR = temp
!       print *, '3 Project_config.f, get_DIR:',trim(get_DIR)

      end if
!       Deallocate (str)
!       in case definition in main is slightly different
!       pre_digitized_XT_pairs = 'no'
!       data_traces = 'no'
!       previous_model = 'no'
!       new_model = 'no'

!      print *, 'Project_config.f, inbound is:', inbound
!      in case inbound is of a different length in main
!       inbound=inbound
!      open(unit=1,file=inbound,status='old')

!       read (1,format1) name,equal,pre_digitized_XT_pairs
!       read (1,format2) name,equal,data_traces
!       read (1,format3) name,equal,clip
!       read (1,format4) name,equal,min_t_n
!       read (1,format5) name,equal,min_x_m

!       Project_directories(2)%str = 'sssssssssss'
!       Project_directories(3)%str = 'q'
!       write(*,'(a)') (Project_directories(i)%str,i=1,3)

!       result = 1

!      if (answer == 'yes')

!      print(*), 'bingo=',result
!      end if


      end subroutine Project_config

!      module variables
!         type string
!           character(len=:), allocatable :: str
!         end type string
!       end module variables
