      subroutine read_bin_data(inbound_bin,ntrmax,nsmax,ntr,ns,Amp)
        implicit none
        
!       read_bin_data reads a fortran-style binary seismic image

       character (len=300) :: inbound_bin, inbound, inbound_locked
       integer*4      :: ntrmax,nsmax,ntr,ns,k,i
       real*4         :: Amp(ntrmax,nsmax)
       integer        :: err_msg, counter, ready

!      trim end and adjustl start of empty spaces
       inbound=trim(adjustl(inbound_bin))
!       print *, 'read_bin_data, inbound_bin is:',inbound,'--'
!       print *, 'read_bin_data, next line:'
       inbound_locked=trim(inbound_bin)//"_locked"
!      print *, 'read_bin_data, inbound_locked is:',trim(inbound_locked),&

!      create a temporary, new, lock file
10     open(status='new',unit=31,file=inbound_locked,iostat=ready)

       if (ready.eq.0) then
       
 20      open(UNIT=21,FILE=inbound_bin,STATUS='OLD',IOSTAT=err_msg, &
         FORM='UNFORMATTED')
         counter = counter +1
!        =0 normal completion, not an error
!        print *, 'L26.read_bin_data.f, err_msg=',err_msg
         
!        check whether file opens data file
         if (err_msg.eq.0) then
!          print *, 'L30.read_bin_data.f,unlocked, err_msg=',err_msg
! read by columns: k          
          k=1     
120        read (unit=21) (Amp(k,i), i=1,ns)

!           i=1
!           do 
!             print*,'k,i,ntr,ns,Amp(k,i)',k,i,ntr,ns,Amp(k,i)
!             i = i+1
!             if(i.GE.ns) go to 50
!           enddo
           
50         if(k.GE.ntr) go to 125
           k=k+1
           go to 120 
125       close (unit=21)

         else
          print *, 'read_bin_data.f, err_msg=',err_msg
          print *,'L53 read_bin_data.f, can not open bin file=',counter

!         rest a little before trying again
!         call sleep(1)
          go to 10
         end if
        
       else
!        print *, 'L61. read_bin_data.f,locked, try again,ready=',ready
!        print *, '3.read_bin_data.f, err_messg=',err_msg
         go to 10
       end if
       
!      remove lock file
11     close (status='delete',unit=31,iostat=err_msg)
!          print *, '4.read_bin_data.f, err_messg=',err_msg

       if (err_msg.ne.0) then
       
        go to 11
!        print *, '5.read_bin_data.f, err_messg=',err_msg
 
       end if
         
!       print *, 'read_bin_data, finished'

      end subroutine read_bin_data
