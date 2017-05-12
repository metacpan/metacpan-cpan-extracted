  ! Modifcation history.

  ! Originally written for the eSTAR LX200 e-science demonstrator.

  ! Modified in August 2003 for the UKIRT tests.  Much of the stuff
  ! which was specific for USNO A2 vs optical data (likely accuracy of
  ! of photometry, number of correlations etc) changed into parameters
  ! set at the head of the corlate code.


  module corlate_subs

    implicit none

    contains

    real function pchisq(chisq)

      real, intent(in) :: chisq

      ! Locals.
      double precision :: term, sum, z
      integer :: i
      double precision, parameter :: gamma=1.77245385d0

      if (chisq > 25.0) then
        pchisq=5.861e-07
      else  
        z = dble(chisq/2.0)
        term = 1.0d0
        sum = 2.0d0*term
        do i=1, 1000
          term = -term * z/dble(i)
          sum = sum + term/(0.5d0+dble(i))
          if (dabs(term/sum) <= 0.00001d0) exit
        end do
        pchisq = 1.0 - (z**0.5)*real(sum/gamma)
      end if

    end function pchisq



    subroutine fit(xdata, ydata, yerr, ndata, a, b, chisq, nclip)

      implicit none

      real, dimension(:), intent(in):: xdata, ydata, yerr
      integer, intent(in) :: ndata
      real, intent(out) :: a, b, chisq
      integer, intent(out) :: nclip

      real :: ss, sx, sxoss, sy, st2
      real, dimension(ndata) :: chi, weight
      integer :: nclip_old, i

      chi = 0.0
      chisq=huge(chisq)
      nclip = -1
      weight=1.0/yerr(1:ndata)**2.0

      do

        nclip_old=nclip
        nclip=0
        do i=1, ndata
          if (chi(i) > 4.0*chisq) then
            weight(i) = 0.0
            nclip=nclip+1
          end if
        end do
        if (nclip_old == nclip) exit

        ss=sum(weight)
        sx=sum(xdata(1:ndata)*weight)
        sy=sum(ydata(1:ndata)*weight)

        sxoss=sx/ss
        b=sum(ydata(1:ndata)*(xdata(1:ndata)-sxoss)*weight)
        st2=sum( ((xdata(1:ndata)-sxoss)**2.0)*weight)
        b=b/st2
        a=(sy-sx*b)/ss

        ! Work out chi and chisq without the zero weighted points.
        chi = ((ydata(1:ndata)-a-b*xdata(1:ndata))**2.0)*weight
        chisq=sum(chi)/real(ndata-nclip)

        ! And now put all the points back.
        weight=1.0/yerr(1:ndata)**2.0
        chi = ((ydata(1:ndata)-a-b*xdata(1:ndata))**2.0)*weight

      end do

    end subroutine fit

    integer function corlate( file_name_1, file_name_2, file_name_3, &
                              file_name_4, file_name_5, file_name_6, &
                              file_name_7, file_name_8 ) 

      ! Finds the nearest match between catalogues in cluster format.

      use define_star
      use cluster_match_subs
      use radec2rad_mod

      implicit none

      ! Inputs.
      ! The names of the various input and output files are in an array.  
      ! The elements are as follows, where catalogues are in cluster format.
      ! 1. Input two colour catalogue (e.g. a digitised sky survey).
      ! 2. Input one colour catalogue (e.g. a new observation).
      ! And now the output files.
      ! 3. The log file.
      ! 4. A cluster catalogue of the variable stars.  The colours are;
      !      1. The difference between colour 1 for the two catalogues, in 
      !         the sense two colour catalogue minus one colour catalogue.
      !      2. Colour two from the two colour catalogue.
      !      3. Colour one fom the two colour catalogue.
      !      4. Colour one from the one colour catalogue.
      !      The field and ID and X,Y are from the one colour catalogue, the 
      !      RA and dec from the two colour catalogue.
      !      The RMS separation between correlated positions in the two 
      !      catalogues is the third field on the first line.
      ! 5. A cluster file of the fitted colour data.  The colours are as 
      !    for file_name_4.
      ! 6. Two points which define the fit to the above.  An X-Y file with
      !    three lines of header. X is colour two, Y is the difference in
      !    colour 1.
      ! 7. The histogram of probablities, as an X-Y file, with three lines
      !    of header.
      ! 8. A file of useful information on the variable stars.

      character(len=*), intent(in):: file_name_1
      character(len=*), intent(in):: file_name_2
      character(len=*), intent(in):: file_name_3
      character(len=*), intent(in):: file_name_4
      character(len=*), intent(in):: file_name_5
      character(len=*), intent(in):: file_name_6
      character(len=*), intent(in):: file_name_7
      character(len=*), intent(in):: file_name_8

      ! Return values are;
      !    0 = success
      !   -1 = failed to open file_name_1
      !   -2 = failed to open file_name_2
      !   -3 = Too few stars paired between catalogues.


      integer :: nstars1, nstars2, ncol1, ncol2
      character(len=3), dimension(mcol) :: colstr1, colstr2
      type(a_star), dimension(:), allocatable :: star1, star2
      real, dimension(:), allocatable :: alpha, delta
      ! Once the stars are paired, we can create a new star record.
      type(a_star), dimension(:), allocatable :: pair
      integer :: npair

      integer :: i, iostat, istar
      real :: fixrad
      integer, dimension(:), allocatable :: matches
      integer :: n_matches
      real :: work

      ! For the fitting.
      real :: a, b, chisq
      integer :: nclip

      ! For calculating the modal separation.
      real :: another_alpha, another_delta
      real :: mod_shift_alpha, mod_shift_delta
      real, dimension(:), allocatable :: dist_alpha, dist_delta
      ! For the mean.
      real :: dist_mean, dist

      ! For the probablility.
      integer, parameter :: mprob=101
      real, dimension(mprob) :: bin
      integer :: nprob, iprob, ibin
      real, allocatable, dimension(:) :: prob
      real :: delta_mag, abs_delta_mag

      ! Some things you may want to tweak.
      ! The minimum number of stars in common you must have.
      integer, parameter :: minpair=3
      ! The lowest signal-to-noise stars you will use in the correlation.
      real, parameter :: lowest_sn=0.2
      ! The false alarm probablility you are prepared to accept.
      real, parameter :: accept_prob=0.05
      ! Set this true if you want to find stars that have faded as well as
      ! those which have brightened.
      logical, parameter :: allow_fading=.true.
      ! The initial search radius.
      real, parameter :: inital_rad=8.0
      ! Search radius after tweaking positions.
      real, parameter :: final_rad=1.0
      ! Minimum change in magnitude to believe variable.
      real, parameter :: min_mag_change=0.5

      ! Start as we mean to go on.
      corlate=0
      open(unit=2, file=file_name_3, status='unknown')

      fixrad=inital_rad

      open(1,file=file_name_1, status='old', iostat=iostat, action='read')
      if (iostat /= 0) then
        corlate=-1
        write(2,*) 'Failed to open archive file ', file_name_1
        close(2)
        close(1)
        return
      end if
      call read_cluster_file(1, nstars1, ncol1, colstr1, star1) 
      close(1)

      ! Make the ra and dec arrays.
      allocate(alpha(nstars1), delta(nstars1))
      do i=1, nstars1
        call radec2rad(star1(i)%ra_h, star1(i)%ra_m, star1(i)%ra_s, &
        star1(i)%dc_d, star1(i)%dc_m, star1(i)%dc_s, alpha(i), delta(i))
      end do

      open(unit=1, file=file_name_2, status='old', iostat=iostat, action='read')
      if (iostat /= 0) then
        corlate=-2
        write(2,*) 'Failed to open new data file ', file_name_2
        close(1)
        close(2)
        return
      end if
      call read_cluster_file(1, nstars2, ncol2, colstr2, star2) 
      close(1)

      ! Remove any variability flags.
      where(star2%col(1)%flg/10 == 6) star2%col(1)%flg=star2%col(1)%flg-60
      where(star2%col(1)%flg - 10*(star2%col(1)%flg/10) == 6) &
      star2%col(1)%flg=star2%col(1)%flg-6

      ! A first run through to tweak up the matching radius.

      allocate(matches(nstars1))
      npair=0

      allocate(dist_alpha(nstars2), dist_delta(nstars2))

      rad: do istar=1, nstars2

        call match_them(nstars1, star1, alpha, delta, star2(istar), &
        fixrad, matches, n_matches)

        if (n_matches > 0) then

          ! Now, go through the reasons for not fitting this star.
          if (star2(istar)%col(1)%err > lowest_sn) cycle rad
          if (star2(istar)%col(1)%flg /= 0) cycle rad
          if (star1(matches(1))%col(1)%flg /= 0) cycle rad
          if (star1(matches(1))%col(2)%flg /= 0) cycle rad

          ! O.K., its one we want.

          npair=npair+1

          ! First find the separation.
          call radec2rad(star2(istar)%ra_h, star2(istar)%ra_m, &
          star2(istar)%ra_s, star2(istar)%dc_d, star2(istar)%dc_m, &
          star2(istar)%dc_s, another_alpha, another_delta)
          dist_alpha(npair)=(another_alpha-alpha(matches(1)))
          dist_delta(npair)=(another_delta-delta(matches(1)))

        end if

      end do rad

      write(2,*) 'Number of pairs for first pass was ', npair

      if (npair < minpair) then
        write(2,*) 'Too few pairs to continue.'
        corlate=-3
        deallocate(matches)
        close(2)
        return
      end if

      dist_alpha=dist_alpha*206264.8
      dist_delta=dist_delta*206264.8*cos(delta(1))
      mod_shift_alpha=median(dist_alpha, npair)
      mod_shift_delta=median(dist_delta, npair)

      deallocate(dist_alpha, dist_delta)

      write(2,*) 'Which gave a modal separations in RA and dec of ', &
      mod_shift_alpha, mod_shift_delta, ' arcseconds.'
      fixrad = final_rad

      mod_shift_alpha=mod_shift_alpha/206264.8
      mod_shift_delta=mod_shift_delta/(206264.8*cos(delta(1)))

      allocate(pair(nstars2))
      npair=0
      dist_mean=0.0

      open(unit=1, file=file_name_5, status='unknown') 
      write(1,*) '4 colours were created'
      write(1,*) trim(colstr1(1))//'-'//trim(colstr2(1)), ' ', &
      trim(colstr1(2)), ' ', trim(colstr2(1)), ' ', trim(colstr1(1)) 
      write(1,*)

      new_star: do istar=1, nstars2

        call match_them(nstars1, star1, alpha+mod_shift_alpha, delta+mod_shift_delta, star2(istar), &
        fixrad, matches, n_matches)

        if (n_matches == 0) then
          ! Not found any match.
          ! call write_star(24, star2(istar), ncol2)
        else

          ! Now, go through the reasons for not fitting this star.
          if (star2(istar)%col(1)%err > lowest_sn) cycle new_star
          if (star2(istar)%col(1)%flg /= 0) cycle new_star
          if (star1(matches(1))%col(1)%flg /= 0) cycle new_star
          if (star1(matches(1))%col(2)%flg /= 0) cycle new_star

          ! O.K., its one we want.

          ! First find the separation.
          call radec2rad(star2(istar)%ra_h, star2(istar)%ra_m, &
          star2(istar)%ra_s, star2(istar)%dc_d, star2(istar)%dc_m, &
          star2(istar)%dc_s, another_alpha, another_delta)
          dist=(another_alpha-alpha(matches(1))-mod_shift_alpha)
          dist=dist*cos((another_delta+delta(matches(1)))/2.0)
          dist=dist**2.0
          dist=dist+(another_delta-delta(matches(1))-mod_shift_delta)**2.0
          dist=sqrt(dist)*206264.8
          dist_mean=dist_mean+(dist*dist)

          npair=npair+1

          ! Set the field and id to those from the new data.
          pair(npair)%field=star2(istar)%field
          pair(npair)%id   =star2(istar)%id

          ! Set the RA and Dec to those from the catalogue.
          pair(npair)%ra_h=star1(matches(1))%ra_h
          pair(npair)%ra_m=star1(matches(1))%ra_m
          pair(npair)%ra_s=star1(matches(1))%ra_s
          pair(npair)%dc_d=star1(matches(1))%dc_d
          pair(npair)%dc_m=star1(matches(1))%dc_m
          pair(npair)%dc_s=star1(matches(1))%dc_s

          ! Set X and Y to those in the image.
          pair(npair)%x = star2(istar)%x
          pair(npair)%y = star2(istar)%y

          ! Set the colours.
          pair(npair)%col(2)=star1(matches(1))%col(2)
          pair(npair)%col(3)=star2(istar)%col(1)
          pair(npair)%col(4)=star1(matches(1))%col(1)
          ! Set colour 1 to be the difference between the colour 1s.
          pair%col(1)%data=pair%col(4)%data - pair%col(3)%data
          pair(npair)%col(1)%err = &
          sqrt(pair(npair)%col(3)%err**2.0 + pair(npair)%col(4)%err**2.0)
          pair(1:npair)%col(1)%flg=0

          call write_star(1, pair(npair), 4)

        end if

      end do new_star
      close(1)

      deallocate(star1, alpha, delta, matches)

      write(2,*) 'Number of pairs for fitting is ', npair

      if (npair >= minpair) then

        dist_mean=sqrt(dist_mean/real(npair))
        write(2,*) 'Whose mean separation is ', dist_mean, ' arcsec.'

        call fit(pair%col(2)%data, pair%col(4)%data - pair%col(3)%data, &
        pair%col(1)%err, npair, a, b, chisq, nclip)

        write(2,*) 'Fit was mag_diff = ', b, '(B-R) + ', a
        write(2,*) 'With a chi-squared of ', chisq
        write(2,*) 'Number of points clipped out was ', nclip

        open(unit=1, file=file_name_6, status='unknown')
        write(1,'(/,/)')
        work=minval(pair(1:npair)%col(2)%data-pair(1:npair)%col(2)%err)
        write(1,*) work, a+b*work
        work=maxval(pair(1:npair)%col(2)%data+pair(1:npair)%col(2)%err)
        write(1,*) work, a+b*work
        close(1)

        open(unit=1, file=file_name_4, status='unknown')
        write(1,*) '4 colours, ', dist_mean, ' arcsec RMS separation.'
        write(1,*) 'd'//colstr2(1), ' ', colstr1(2), ' ', &
        colstr2(1), ' ', colstr1(1)
        write(1,*)
        open(unit=3, file=file_name_8, status='unknown')
        write(3,*) dist_mean, &
        '! Mean separation in arcsec of stars successfully paired.'
        allocate(prob(npair)) 
        nprob=0
        do istar=1, npair
          delta_mag = pair(istar)%col(1)%data - a-b*pair(istar)%col(2)%data
          !print*, delta_mag
          if (allow_fading) then
            abs_delta_mag=abs(delta_mag)
          else
            abs_delta_mag=delta_mag
          end if
          if (abs_delta_mag > min_mag_change) then
            nprob=nprob+1
            ! Work out the probablility, after scaling the error bar by chisq.
            prob(nprob)= &
            pchisq(((abs_delta_mag/pair(istar)%col(1)%err)**2.0)/chisq)
            prob(nprob)=1.0-(1.0-prob(nprob))**real(npair)
            ! One day we should correct the above to be two 
            ! sided if (allow_fading).
            if (prob(nprob) < accept_prob) then
              ! Change colour 1 to be the change in magnitde.
              pair(istar)%col(1)%data = -delta_mag
              call write_star(1, pair(istar), 4)
              write(3,*) '!! Begining of new star description.'
              write(3,*) colstr2(1), '! Filter observed in.'
              write(3,*) delta_mag, '! Increase brightness in magnitudes.'
              write(3,*) sqrt(pair(istar)%col(3)%err**2.0 &
                            + pair(istar)%col(4)%err**2.0), '! Error in above.'
              write(3,*) prob(nprob), '! False alarm probability.'
              write(3,*) pair(istar)%ra_h, pair(istar)%ra_m, &
              pair(istar)%ra_s, '! Target RA from archive catalogue.'
              write(3,*) pair(istar)%dc_d, pair(istar)%dc_m, &
              pair(istar)%dc_s, '! Target Declination from archive catalogue.'
            end if
          end if
        end do
        close(1)
        close(3)

        where(prob(1:nprob) > tiny(prob(1))) prob(1:nprob)=-log10(prob(1:nprob))

        ! Now make a histogram.
        bin=0.0
        do iprob=1, nprob
          ibin=int(real(mprob-1)*prob(iprob)/maxval(prob(1:nprob)))+1
          bin(ibin)=bin(ibin)+1
        end do

        open(unit=1, file=file_name_7, status='unknown')
        write(1,'(/,/)')
        !write(1,*) &
        !  10.0**(((           0.5)/real(-mprob))*maxval(prob(1:nprob))), &
        !  0.0
        !do i=1, mprob
        !  write(1,*) &
        !  10.0**(((real(i    )+0.5)/real(-mprob))*maxval(prob(1:nprob))), &
        !  bin(i)
        !end do
        !write(1,*) &
        !  10.0**(((real(mprob)+1.5)/real(-mprob))*maxval(prob(1:nprob))), &
        !  0.0
        close(1)

        deallocate(prob)

      else

        write(2,*) 'Too few pairs to continue.'
        corlate=-3

      end if
      
      deallocate(pair)
      close(2)

            
    end function corlate

    real function median(srtbuf, nfile)

      ! Finds the median value in steps of 1.  Needs generalising.

      real, intent(out), dimension(:) :: srtbuf
      integer, intent(in) :: nfile

      integer :: k, l, m
      real :: aval
      integer, dimension(:), allocatable :: count

      do 140 k=2, nfile
        aval=srtbuf(k)
        do l=1, k-1
          if (aval .lt. srtbuf(l)) then
            do m=k, l+1, -1
              srtbuf(m)=srtbuf(m-1)
            end do
            srtbuf(l)=aval
            goto 140
          endif
        end do
140   continue

      allocate(count(nint(srtbuf(1)):nint(srtbuf(nfile))))
      count=0
      do k=1, nfile
        l=nint(srtbuf(k))
        count(l)=count(l)+1
      end do
      median=real(minval(maxloc(count)))+nint(srtbuf(1))-1
      deallocate(count)

    end function median

  end module corlate_subs
